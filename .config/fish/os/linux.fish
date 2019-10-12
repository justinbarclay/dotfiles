# Path to Oh My Fish install.
set -q XDG_DATA_HOME
  and set -gx OMF_PATH "$XDG_DATA_HOME/omf"
  or set -gx OMF_PATH "$HOME/.local/share/omf"

# Load Oh My Fish configuration.
source $OMF_PATH/init.fish

export WINDOWS_HOST=(grep -oP "(?<=nameserver ).+" /etc/resolv.conf | awk '{printf $1; exit}' )
export DISPLAY=$WINDOWS_HOST":0"

export AWS_REGION="ca-central-1"

export EDITOR="emacs"


export locale=en_US.UTF-8
