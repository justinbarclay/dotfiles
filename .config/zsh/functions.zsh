#########################
# Aliases
#########################
alias ls="exa -lbh"

alias rails="noglob rails"

#########################
# Functions
#########################
emacs () {
    /usr/sbin/emacs $argv &
}

delete-merged () {
  git branch --merged \
    | egrep -v "(^\*|master|dev)" \
    | xargs git branch -d
}

#########################
# Work functions
#########################

cdwa () {
  cd ~/dev/tidal/application-inventory/
}

count-releases-mm () {
  git log --tags='release-v*' --simplify-by-decoration --pretty="format:%ci %d" --since='2 weeks' \
    | grep "tag: release" \
    | wc -l
}
