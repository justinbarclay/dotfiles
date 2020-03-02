case $(uname) in
  Linux)
    source $HOME/.config/zsh/os/linux.zsh
    ;;
  Darwin)
    source $HOME/.config/zsh/os/darwin.zsh
    ;;
  '*')
    echo Hi, stranger!
    ;;
esac

export DEFAULT_USER="Justin 🐯"

# source ~/.config/fish/secrets/work.fish
# source ~/.config/fish/secrets/personal.fish
# Add custom functions
source $HOME/.config/zsh/functions.zsh

# Configuration specific to zinit
source $HOME/.config/zsh/zinit.zsh

eval $(starship init zsh)
