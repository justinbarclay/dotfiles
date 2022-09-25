#########################
# Aliases
#########################
alias ls="exa -lbh"

alias rails="noglob rails"

#########################
# Functions
#########################
emacs () {
  /home/justin/.nix-profile/bin/emacs $argv &
}

delete-merged () {
  git branch --merged \
    | egrep -v "(^\*|master|dev)" \
    | xargs git branch -d
}

# George Ornbo (shapeshed) http://shapeshed.com
# License - http://unlicense.org
#
# Fixes a corrupt .zsh_history file

clean_history() {
  mv ~/.zsh_history ~/.zsh_history_bad
  strings ~/.zsh_history_bad > ~/.zsh_history
  fc -R ~/.zsh_history
  rm ~/.zsh_history_bad
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
