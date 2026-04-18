# dotfiles

Nix-based dotfiles for macOS (heimdall) and NixOS WSL (vider), managed with [home-manager](https://github.com/nix-community/home-manager) and [nix-darwin](https://github.com/LnL7/nix-darwin). A separate `windows/` directory covers the native Windows host that runs WezTerm + WSL.

## Machines

| Host | OS | Arch | Config |
|------|----|------|--------|
| `heimdall` | macOS | aarch64-darwin | `darwinConfigurations.heimdall` |
| `vider` | NixOS WSL | x86_64-linux | `nixosConfigurations.vider` |
| *(Windows host)* | Windows 11 | x86_64 | `windows/bootstrap.nu` |

## Prerequisites

### Both machines
- [Nix](https://determinate.systems/posts/determinate-nix-installer) with flakes enabled
- [1Password CLI](https://developer.1password.com/docs/cli/) (`op`) signed in
- SSH key added to 1Password and configured for commit signing

### macOS only
- [nix-darwin](https://github.com/LnL7/nix-darwin) bootstrapped once:
  ```bash
  nix run nix-darwin -- switch --flake ~/dotfiles/home-manager
  ```

### WSL only
- [NixOS-WSL](https://github.com/nix-community/NixOS-WSL) installed

### Windows (native host) only
- **winget** available — ships with Windows 10 1809+ via *App Installer*; update it from the Microsoft Store if needed
- The repo cloned somewhere (e.g. `%USERPROFILE%\dotfiles`) — Git for Windows is installed *by* the bootstrap, so a plain `winget install Git.Git` or the GitHub Desktop bundled Git is sufficient to clone

## Deploying

### macOS (heimdall)

```bash
# Full system rebuild (system config + homebrew + services)
rebuild-darwin

# Home config only
home-manager switch --flake ~/dotfiles/home-manager#justin@heimdall
```

### WSL (vider)

```bash
# System config
rebuild-nix

# Home config
home-manager switch --flake ~/dotfiles/home-manager#justin@nixos
```

### Windows (native host)

```powershell
# From a plain PowerShell prompt — no Nushell required.
# Clone the repo first, then:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\windows\bootstrap.ps1
```

`bootstrap.ps1` installs Nushell via winget and then calls `bootstrap.nu`, which:
1. Installs [Scoop](https://scoop.sh) if missing
2. Adds Scoop buckets and installs CLI tools from `windows/scoop.json`
3. Installs remaining GUI apps via `winget import windows/winget.json`
4. Symlinks config files (nushell, wezterm, git, komorebi, whkd, starship) to their Windows locations

```nu
# Upgrade all packages and re-export manifests (after initial setup):
nu windows/update.nu
```

### Update everything (flake inputs + home-manager switch)

```bash
nix-update
```

> **Note:** `nix-update` currently uses `--impure` to read `fastmailUsername` from 1Password at eval time. This can be eliminated by hardcoding the email address in `home.nix` since it is not a secret — the password is already fetched at runtime via `passwordCommand`.

## Structure

```
home-manager/
├── flake.nix          # Entry point — inputs, overlays, system outputs
├── home.nix           # Home Manager config shared across machines
├── darwin.nix         # macOS system config (nix-darwin)
├── wsl.nix            # NixOS WSL system config
├── emacs.nix          # Emacs + LSP + mu4e
├── email.nix          # Fastmail via mbsync + msmtp + mu
├── git.nix            # Git + SSH commit signing via 1Password
├── gtk.nix            # GTK theme (Linux only, Tokyo Night)
├── nushell.nix        # Nushell + starship + atuin + zoxide + carapace
├── zsh.nix            # Zsh (disabled, nushell is primary)
├── config/            # Raw config files (wezterm, nushell, starship, sketchybar)
├── packages/          # Custom Nix packages (pngpaste, pt-mono-nerd-font)
├── scripts/           # nix-update, rebuild-nix
└── services/          # Darwin launchd services (redis, pueue, mbsync, postgres)
windows/
├── bootstrap.ps1      # Step 1: run from plain PowerShell — installs Nushell then calls bootstrap.nu
├── bootstrap.nu       # Step 2: full first-time setup (Scoop, Winget, symlinks)
├── update.nu          # Upgrade all packages + re-export manifests
├── winget.json        # Declarative Winget manifest (GUI apps, core tools)
├── scoop.json         # Declarative Scoop manifest (CLI dev tools)
├── .gitconfig         # Native Windows git config (correct SSH/signing paths)
├── komorebi.json      # Tiling WM config (mirrors AeroSpace on macOS)
└── whkdrc             # Hotkey config for whkd (mirrors AeroSpace bindings)
```

## SSH & Commit Signing Setup

Git is configured to sign commits with your SSH key via 1Password.

1. Generate or import your key into 1Password
2. Enable the SSH agent in 1Password → Settings → Developer
3. Verify the key path in `git.nix` matches your 1Password SSH agent socket
4. On WSL, `op-ssh-sign-wsl.exe` must be on your Windows PATH
5. On the native Windows host, `windows/.gitconfig` points directly to the 1Password `op-ssh-sign.exe` binary; adjust the path if your 1Password installation differs from the default

The public key used for verification is stored in `config/.gitconfig-darwin` and `config/.gitconfig-wsl` under `[gpg.ssh] allowedSignersFile`.

## Key Software

| Tool | Purpose |
|------|---------|
| [aerospace](https://github.com/nikitabobko/AeroSpace) | Tiling window manager (macOS), 6 workspaces |
| [komorebi](https://github.com/LGUG2Z/komorebi) | Tiling window manager (Windows), mirrors AeroSpace layout |
| [whkd](https://github.com/LGUG2Z/whkd) | Hotkey daemon for komorebi (Windows) |
| [sketchybar](https://github.com/FelixKratz/SketchyBar) | Status bar (macOS) |
| [nushell](https://www.nushell.sh) | Primary shell |
| [atuin](https://github.com/atuinsh/atuin) | Shell history sync |
| [emacs-igc](https://github.com/emacs-mirror/emacs) | Editor with incremental GC |
| [mu4e](https://djcbsoftware.nl/code/mu/mu4e.html) | Email in Emacs |
| [mbsync](https://isync.sourceforge.io) | IMAP sync (Fastmail) |
| [pueue](https://github.com/Nukesor/pueue) | Background task queue |
| [podman](https://podman.io) | Daemonless containers (docker-compatible) |

## CI

GitHub Actions runs two jobs on every push and PR:

1. **format** — `nixpkgs-fmt --check` on all `.nix` files
2. **parse** — `nix-instantiate --parse` on all `.nix` files (catches syntax errors the formatter misses)

> Full flake evaluation (`nix flake check`) is not run in CI because the private SSH inputs (`tidal-overlay`, `tidal-tools`) require deploy keys that are not available in the public CI environment.

## Legacy / archived paths

| Path | Status |
|------|--------|
| `guix/` | Archived — predates the Nix setup; kept for historical reference |
| `setup.sh` | Archived — old zsh symlink bootstrap; superseded by `windows/bootstrap.ps1` and nix-darwin |
| `setup.org` | Archived — old Arch/Guix notes; superseded by this README |
