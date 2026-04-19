#!/bin/sh
# ARCHIVED: This script predates the Nix/home-manager setup and is no longer
# used. It is kept for historical reference only.
# The current bootstrap is windows/bootstrap.ps1 (Windows) or the nix-darwin /
# NixOS-WSL instructions in README.md.
script_dir=$(dirname $0 | xargs realpath)

zsh () {
  mkdir -p ~/.config
  ln -s $script_dir/.zprofile ~/.zprofile
  ln -s $script_dir/zsh ~/.config
  ln -s $script_dir/home-manager ~/.config
}

if [ "$1" == "zsh" ]; then
  zsh
else
  echo Command unknown
  echo This script is built to setup config files for
  echo zsh.
fi
