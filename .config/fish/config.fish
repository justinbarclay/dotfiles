# Path to Oh My Fish install.
set -q XDG_DATA_HOME
  and set -gx OMF_PATH "$XDG_DATA_HOME/omf"
  or set -gx OMF_PATH "$HOME/.local/share/omf"

# Load Oh My Fish configuration.
source $OMF_PATH/init.fish

switch (uname)
    case Linux
         source ./os/linux.fish
    case Darwin
              source ./os/darwin.fish
    case '*'
            echo Hi, stranger!
end

set -g default_user "Justin 🐯"

source ~/.config/fish/secrets/work.fish
# source ~/.config/fish/secrets/personal.fish


# Agnoster Customizations specific for Dracula
set -g theme_display_user yes
set -g theme_hide_hostname yes
eval (starship init fish)
