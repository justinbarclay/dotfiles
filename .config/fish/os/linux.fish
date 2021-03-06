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
export DOTNET_ROOT="/opt/dotnet"

# are we in the bottle?
# if test ! -n "$INSIDE_GENIE"
#   timeout 3s fish -c 'read yn -P "Preparing to enter genie bottle (in 3s); abort? (y/n) "'
#   # echo

#   if not test $yn = "y"
#     echo "Starting genie:"
#     exec /usr/bin/genie -s
#   end
# end

export locale=en_US.UTF-8
