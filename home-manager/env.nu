let-env EDITOR = "emacs"

let-env PATH = ($env.PATH | split row (char esep) | prepend [$"($env.HOME)/.local/bin",$"($env.HOME)/bin",$"($env.HOME)/.cargo/bin",$"($env.HOME)/.config/home-manager/scripts"])
let-env AWS_REGION = ca-central-1


mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu

if (not (sys | get host.name) == "Darwin") {
  let-env WINDOWS_HOST = (grep -oP "(?<=nameserver ).+" /etc/resolv.conf | awk "{printf $1; exit}")
  let-env DISPLAY = ($env.WINDOWS_HOST + ":0")
}
