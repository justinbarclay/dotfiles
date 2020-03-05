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

export DEFAULT_USER="Justin 🐯";

# source ~/.config/fish/secrets/work.fish
# source ~/.config/fish/secrets/personal.fish
# Add custom functions
source $HOME/.config/zsh/functions.zsh;

# Configuration specific to zinit
source $HOME/.config/zsh/zinit.zsh;

# Track history
export HISTFILE=$HOME/.zsh_history;

# how many lines of history to keep in memory
HISTSIZE=10000;

# how many lines to keep in the history file
SAVEHIST=10000;

setopt hist_ignore_all_dups

eval $(starship init zsh)
