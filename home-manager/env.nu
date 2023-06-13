let starship_cache = "/home/justin/.cache/starship"
if not ($starship_cache | path exists) {
  mkdir $starship_cache
}
/home/justin/.nix-profile/bin/starship init nu | save --force /home/justin/.cache/starship/init.nu

let-env EDITOR = "emacs"

let-env PATH = ($env.PATH | split row (char esep) | prepend [$"($env.HOME)/.local/bin",$"($env.HOME)/bin",$"($env.HOME)/.cargo/bin",$"($env.HOME)/.config/home-manager/scripts"])

let-env WINDOWS_HOST = (grep -oP "(?<=nameserver ).+" /etc/resolv.conf | awk "{printf $1; exit}")
let-env DISPLAY = ($env.WINDOWS_HOST + ":0")
