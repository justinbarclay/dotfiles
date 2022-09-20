#!/bin/sh
script_dir=$(dirname $0 | xargs realpath)
fish () {
  mkdir -p ~/.config
  ln -s $script_dir/.config/fish ~/.config
  ln -s $script_dir/.Xmodmap ~/.Xmodmap
}

zsh () {
  mkdir -p ~/.config
  ln -s $script_dir/.zshrc ~/.zshrc
  ln -s $script_dir/.config/zsh ~/.config
  ln -s $script_dir/.Xmodmap ~/.Xmodmap
}

if [ "$1" == "zsh" ]; then
  zsh
elif [ "$1" == "fish" ]; then
  fish
else
  echo Command unknown
  echo This script is built to setup config files for
  echo fish or zsh.
fi
