$env.EDITOR = "emacs"

$env.PATH = ($env.PATH | split row (char esep) | prepend [$"($env.HOME)/.local/bin",$"($env.HOME)/bin",$"($env.HOME)/.cargo/bin",$"($env.HOME)/.config/home-manager/scripts"])
$env.AWS_REGION = ca-central-1

zoxide init nushell | str replace --string --all 'let-env ' '$env.' | save -f ~/.cache/zoxide/init.nu

mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu

if (not (sys | get host.name) == "Darwin") {
  $env.WINDOWS_HOST = (grep -oP "(?<=nameserver ).+" /etc/resolv.conf | awk "{printf $1; exit}")
  $env.DISPLAY = ($env.WINDOWS_HOST + ":0")
}
