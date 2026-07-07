$env.EDITOR = "emacs"

if (not ((sys host | get name) == "Windows")) {
   $env.PATH = ($env.PATH | split row (char esep) | prepend [$"($env.HOME)/.local/bin",$"($env.HOME)/bin",$"($env.HOME)/.cargo/bin"])
   $env.AWS_REGION = "ca-central-1"
}

mkdir ($nu.home-dir | path join ".config/starship")
starship init nu | save -f ($nu.home-dir | path join ".config/starship/starship.nu")

mkdir ($nu.home-dir | path join ".config/zoxide")
zoxide init nushell | save -f ($nu.home-dir | path join ".config/zoxide/init.nu" )

mkdir ($nu.home-dir | path join ".cache/carapace")
$env.CARAPACE_BRIDGES = 'zsh,fish,bash'
carapace _nushell | save -f ($nu.home-dir | path join ".cache/carapace/init.nu")

# Generated unconditionally so config.nu's `source` always has a file to parse.
# Only Windows actually initializes atuin here: on NixOS/Darwin, home-manager's
# `programs.atuin.enableNushellIntegration` (nushell.nix) already wires it in
# via nushell's vendor-autoload mechanism, so this stays a no-op there.
mkdir ($nu.home-dir | path join ".config/atuin")
if ((sys host | get name) == "Windows") {
  atuin init nu --disable-up-arrow | save -f ($nu.home-dir | path join ".config/atuin/init.nu")
} else {
  "" | save -f ($nu.home-dir | path join ".config/atuin/init.nu")
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
