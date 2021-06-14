export WINDOWS_HOST=$(grep -oP "(?<=nameserver ).+" /etc/resolv.conf | awk '{printf $1; exit}' )
export DISPLAY=$WINDOWS_HOST":0"

export EDITOR="emacs"

export PATH=~/.local/bin:$PATH
export locale=en_US.UTF-8

# Redefine keymappings to better interop with windows.
#xkbcomp -w 0 ~/.config/zsh/os/xkbmap $DISPLAY
