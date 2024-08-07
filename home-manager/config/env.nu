$env.EDITOR = "emacs"

if (not ((sys host | get name) == "Windows")) {
   $env.PATH = ($env.PATH | split row (char esep) | prepend [$"($env.HOME)/.local/bin",$"($env.HOME)/bin",$"($env.HOME)/.cargo/bin"])
   $env.AWS_REGION = ca-central-1
}

zoxide init nushell |
  str replace "def-env" "def --env" --all |  # https://github.com/ajeetdsouza/zoxide/pull/632
  str replace --all "-- $rest" "-- ...$rest" |
  save --force ~/.cache/zoxide/init.nu

if ((sys host | get name) == "NixOS") {
  $env.WINDOWS_HOST = (ip route | grep default | awk '{print $3; exit;}')
  $env.DISPLAY = ($env.WINDOWS_HOST + ":0")
}
