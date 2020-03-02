case $(uname) in
  Linux)
    source /home/justin/dev/dotfiles/.config/zsh/os/linux.zsh
    ;;
  Darwin)
    source /home/justin/.config/zsh/os/darwin.zsh
    ;;
  '*')
    echo Hi, stranger!
    ;;
esac

export DEFAULT_USER="Justin 🐯"

# Setup cargo and rustup
source $HOME/.cargo/env

# source ~/.config/fish/secrets/work.fish
# source ~/.config/fish/secrets/personal.fish

# Configuration specific to zinit
source ~/dev/dotfiles/.config/zsh/zinit.zsh
eval $(starship init zsh)
