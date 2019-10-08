# Path to Oh My Fish install.
set -q XDG_DATA_HOME
  and set -gx OMF_PATH "$XDG_DATA_HOME/omf"
  or set -gx OMF_PATH "$HOME/.local/share/omf"

# Load Oh My Fish configuration.
source $OMF_PATH/init.fish

set -g default_user "Justin 🐯"



export WINDOWS_HOST=(grep -oP "(?<=nameserver ).+" /etc/resolv.conf)
export DISPLAY=$WINDOWS_HOST":0"
export AWS_REGION="ca-central-1"
# export RUSTC="/Users/Justin/.cargo/bin/rustc"
export EDITOR="/usr/local/bin/emacs"
source ~/.config/fish/secrets/work.fish
# source ~/.config/fish/secrets/personal.fish


# Agnoster Customizations specific for Dracula
set -g theme_display_user yes
set -g theme_hide_hostname yes
eval (starship init fish)