export WINDOWS_HOST=$(grep -oP "(?<=nameserver ).+" /etc/resolv.conf | awk '{printf $1; exit}' )
export DISPLAY=$WINDOWS_HOST":0"

export EDITOR="emacs"

export locale=en_US.UTF-8
