$env.EDITOR = "emacs"

if (not ((sys host | get name) == "Windows")) {
   $env.PATH = ($env.PATH | split row (char esep) | prepend [$"($env.HOME)/.local/bin",$"($env.HOME)/bin",$"($env.HOME)/.cargo/bin"])
   $env.AWS_REGION = "ca-central-1"
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
  starship init nu | save -f ($nu.home-dir | path join ".config/starship/starship.nu")
  zoxide init nushell | save -f ($nu.home-dir | path join ".config/zoxide/init.nu")
  atuin init nu --disable-up-arrow | save -f ($nu.home-dir | path join ".config/atuin/init.nu")
  carapace _carapace nushell | save -f ($nu.home-dir | path join ".cache/carapace/init.nu")
} else {
  "" | save -f ($nu.home-dir | path join ".config/starship/starship.nu")
  "" | save -f ($nu.home-dir | path join ".config/zoxide/init.nu")
  "" | save -f ($nu.home-dir | path join ".config/atuin/init.nu")
  "" | save -f ($nu.home-dir | path join ".cache/carapace/init.nu")
}

if ((sys host | get name) == "NixOS") {
  $env.WINDOWS_HOST = (ip route | grep default | awk '{print $3; exit;}')
  $env.DISPLAY = ($env.WINDOWS_HOST + ":0")
}

if ((sys host | get name) == "Windows") {
  $env.KOMOREBI_CONFIG_HOME = ($nu.home-dir | path join ".config" "komorebi")
  $env.AWS_REGION = "ca-central-1"
  # Prepend Scoop shims and 1Password CLI so they shadow system installs
  $env.PATH = ($env.PATH | split row (char esep) | prepend [
    $"($nu.home-dir)/scoop/shims",
    $"($env.LOCALAPPDATA)/1Password/app/8",
  ])
}

if ((sys host | get name) == "Darwin") {
  $env.PATH = ($env.PATH | split row (char esep) | prepend ['/opt/homebrew/bin', '/opt/podman/bin'])
}
