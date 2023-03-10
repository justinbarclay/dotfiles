#!/bin/sh
script_dir=$(dirname $0 | xargs realpath)

zsh () {
  mkdir -p ~/.config
  ln -s $script_dir/.zprofile ~/.zprofile
  ln -s $script_dir/zsh ~/.config
  ln -s $script_dir/nixpkgs ~/.config
}

if [ "$1" == "zsh" ]; then
  zsh
else
  echo Command unknown
  echo This script is built to setup config files for
  echo zsh.
fi
