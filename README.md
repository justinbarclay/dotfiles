# dotfiles

Nix-based dotfiles for macOS (heimdall) and NixOS WSL (vider), managed with [home-manager](https://github.com/nix-community/home-manager) and [nix-darwin](https://github.com/LnL7/nix-darwin).

## Machines

| Host | OS | Arch | Config |
|------|----|------|--------|
| `heimdall` | macOS | aarch64-darwin | `darwinConfigurations.heimdall` |
| `vider` | NixOS WSL | x86_64-linux | `nixosConfigurations.vider` |

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
```

## SSH & Commit Signing Setup

Git is configured to sign commits with your SSH key via 1Password.

1. Generate or import your key into 1Password
2. Enable the SSH agent in 1Password → Settings → Developer
3. Verify the key path in `git.nix` matches your 1Password SSH agent socket
4. On WSL, `op-ssh-sign-wsl.exe` must be on your Windows PATH

The public key used for verification is stored in `config/.gitconfig-darwin` and `config/.gitconfig-wsl` under `[gpg.ssh] allowedSignersFile`.

## Key Software

| Tool | Purpose |
|------|---------|
| [aerospace](https://github.com/nikitabobko/AeroSpace) | Tiling window manager (macOS), 6 workspaces |
| [sketchybar](https://github.com/FelixKratz/SketchyBar) | Status bar (macOS) |
| [nushell](https://www.nushell.sh) | Primary shell |
| [atuin](https://github.com/atuinsh/atuin) | Shell history sync |
| [emacs-igc](https://github.com/emacs-mirror/emacs) | Editor with incremental GC |
| [mu4e](https://djcbsoftware.nl/code/mu/mu4e.html) | Email in Emacs |
| [mbsync](https://isync.sourceforge.io) | IMAP sync (Fastmail) |
| [pueue](https://github.com/Nukesor/pueue) | Background task queue |
| [podman](https://podman.io) | Daemonless containers (docker-compatible) |

## CI

GitHub Actions runs `nixpkgs-fmt --check` on all `.nix` files on every push and PR. Private flake inputs (`tidal-overlay`, `tidal-tools`) mean full evaluation cannot run in CI without deploy keys.
