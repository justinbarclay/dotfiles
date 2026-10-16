$env.EDITOR = "emacs"

if (not ((sys host | get name) == "Windows")) {
   $env.PATH = ($env.PATH | split row (char esep) | prepend [$"($env.HOME)/.local/bin",$"($env.HOME)/bin",$"($env.HOME)/.cargo/bin"])
   $env.AWS_REGION = "ca-central-1"
}

if ((sys host | get name) == "Windows") {
  $env.KOMOREBI_CONFIG_HOME = ($nu.home-dir | path join ".config" "komorebi")
  $env.AWS_REGION = "ca-central-1"
  # Prepend Scoop shims, WinGet links, and Starship so they are on PATH before init generation
  let win_paths = [
    $"($nu.home-dir)/scoop/shims",
    $"($nu.home-dir)/scoop/apps/starship/current",
    $"($env.LOCALAPPDATA)/1Password/app/8",
    $"($env.LOCALAPPDATA)/Microsoft/WinGet/Links",
    "C:/Program Files/starship/bin",
    $"($nu.home-dir)/.cargo/bin",
  ] | where { |p| $p | path exists }
  $env.PATH = ($env.PATH | split row (char esep) | prepend $win_paths | uniq)
}

if ((sys host | get name) == "Darwin") {
  $env.PATH = ($env.PATH | split row (char esep) | prepend ['/opt/homebrew/bin', '/opt/podman/bin'])
}

if ((sys host | get name) == "NixOS") {
  $env.WINDOWS_HOST = (ip route | grep default | awk '{print $3; exit;}')
  $env.DISPLAY = ($env.WINDOWS_HOST + ":0")
  # Use the Windows mkcert CA so WSL and Windows share one root (see wsl.nix)
  $env.CAROOT = "/mnt/c/Users/justin/AppData/Local/mkcert"
}

# config.nu `source`s these four files unconditionally, and `source` resolves at
# parse time, so each one has to exist before the shell starts.
#
# Windows has no package manager wiring these integrations up, so generate them
# here. Everywhere else nix/home-manager installs the real thing already —
# starship/zoxide/atuin are appended to config.nu by home-manager, and carapace
# is baked into ~/.config/nushell/autoload at build time (see nushell.nix) — so
# these stay empty stubs instead of costing a subprocess on every startup.
mkdir ($nu.home-dir | path join ".config/starship")
mkdir ($nu.home-dir | path join ".config/zoxide")
mkdir ($nu.home-dir | path join ".config/atuin")
mkdir ($nu.home-dir | path join ".cache/carapace")

# Bridged completers. Read by carapace at completion time, not at init time.
$env.CARAPACE_BRIDGES = 'zsh,fish,bash'

if ((sys host | get name) == "Windows") {
  if (which starship | is-not-empty) {
    starship init nu | save -f ($nu.home-dir | path join ".config/starship/starship.nu")
  } else {
    "" | save -f ($nu.home-dir | path join ".config/starship/starship.nu")
  }

  if (which zoxide | is-not-empty) {
    zoxide init nushell | save -f ($nu.home-dir | path join ".config/zoxide/init.nu")
  } else {
    "" | save -f ($nu.home-dir | path join ".config/zoxide/init.nu")
  }

  if (which atuin | is-not-empty) {
    atuin init nu --disable-up-arrow | save -f ($nu.home-dir | path join ".config/atuin/init.nu")
  } else {
    "" | save -f ($nu.home-dir | path join ".config/atuin/init.nu")
  }

  if (which carapace | is-not-empty) {
    carapace _carapace nushell
    | str replace "let carapace_completer = {|spans|" "let carapace_completer = {|place|\n  let spans = $place.command"
    | save -f ($nu.home-dir | path join ".cache/carapace/init.nu")
  } else {
    "" | save -f ($nu.home-dir | path join ".cache/carapace/init.nu")
  }
} else {
  "" | save -f ($nu.home-dir | path join ".config/starship/starship.nu")
  "" | save -f ($nu.home-dir | path join ".config/zoxide/init.nu")
  "" | save -f ($nu.home-dir | path join ".config/atuin/init.nu")
  "" | save -f ($nu.home-dir | path join ".cache/carapace/init.nu")
}
