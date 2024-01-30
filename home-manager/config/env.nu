$env.EDITOR = "emacs"

if (not (sys | get host.name) == "Windows") {
   $env.PATH = ($env.PATH | split row (char esep) | prepend [$"($env.HOME)/.local/bin",$"($env.HOME)/bin",$"($env.HOME)/.cargo/bin",$"($env.HOME)/.config/home-manager/scripts"])
   $env.AWS_REGION = ca-central-1
}
mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu

zoxide init nushell |
  str replace "def-env" "def --env" --all |  # https://github.com/ajeetdsouza/zoxide/pull/632
  str replace --all "-- $rest" "-- ...$rest" |
  save --force ~/.cache/zoxide/init.nu

if ((sys | get host.name) == "NixOS") {
  $env.WINDOWS_HOST = (grep -oP "(?<=nameserver ).+" /etc/resolv.conf | awk "{printf $1; exit}")
  $env.DISPLAY = ($env.WINDOWS_HOST + ":0")
}
