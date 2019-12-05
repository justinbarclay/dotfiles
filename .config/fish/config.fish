switch (uname)
    case Linux
         source /home/justin/.config/fish/os/linux.fish
    case Darwin
         source /home/justin/.config/fish/os/darwin.fish
    case '*'
            echo Hi, stranger!
end

set -g default_user "Justin 🐯"

# source ~/.config/fish/secrets/work.fish
# source ~/.config/fish/secrets/personal.fish

eval (starship init fish)
