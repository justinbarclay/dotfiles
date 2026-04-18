$env.EDITOR = "emacs"

if (not ((sys host | get name) == "Windows")) {
   $env.PATH = ($env.PATH | split row (char esep) | prepend [$"($env.HOME)/.local/bin",$"($env.HOME)/bin",$"($env.HOME)/.cargo/bin"])
   $env.AWS_REGION = "ca-central-1"
}

mkdir ($nu.home-dir | path join ".config/starship")
starship init nu | save -f ($nu.home-dir | path join ".config/starship/starship.nu")

mkdir ($nu.home-dir | path join ".config/zoxide")
zoxide init nushell | save -f ($nu.home-dir | path join ".config/zoxide/init.nu" )

if ((sys host | get name) == "NixOS") {
  $env.WINDOWS_HOST = (ip route | grep default | awk '{print $3; exit;}')
  $env.DISPLAY = ($env.WINDOWS_HOST + ":0")
}

if ((sys host | get name) == "Windows") {
  $env.KOMOREBI_CONFIG_HOME = $"($nu.home-dir)/.config/komorebi"
  $env.AWS_REGION = "ca-central-1"
  # Prepend Scoop shims and 1Password CLI so they shadow system installs
  $env.PATH = ($env.PATH | split row (char esep) | prepend [
    $"($nu.home-dir)/scoop/shims",
    $"($env.LOCALAPPDATA)/1Password/app/8",
  ])
}

if ((sys host | get name) == "Darwin") {
  $env.PATH = ($env.PATH | split row (char esep) | prepend '/opt/homebrew/bin')
}
