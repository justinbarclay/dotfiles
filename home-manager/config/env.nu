$env.EDITOR = "emacs"

if (not ((sys host | get name) == "Windows")) {
   $env.PATH = ($env.PATH | split row (char esep) | prepend [$"($env.HOME)/.local/bin",$"($env.HOME)/bin",$"($env.HOME)/.cargo/bin"])
   $env.AWS_REGION = "ca-central-1"
}

mkdir ($nu.home-path | path join ".config/starship")
starship init nu | save -f ($nu.home-path | path join ".config/starship/starship.nu")

mkdir ($nu.home-path | path join ".config/zoxide")
zoxide init nushell | save -f ($nu.home-path | path join ".config/zoxide/init.nu" )

if ((sys host | get name) == "NixOS") {
  $env.WINDOWS_HOST = (ip route | grep default | awk '{print $3; exit;}')
  $env.DISPLAY = ($env.WINDOWS_HOST + ":0")
}

if ((sys host | get name) == "Windows") {
  $env.KOMOREBI_CONFIG_HOME = $"($env.HOME)/.config/komorebi"
}

if ((sys host | get name) == "Darwin") {
  $env.PATH = ($env.PATH | split row (char esep) | prepend '/opt/homebrew/bin')
}
