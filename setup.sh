#!/bin/bash
rm ~/.hyper.js
ln -s ~/dotfiles/.hyper.js ~/.hyper.js

mkdir -p ~/.config
ln -s ~/dotfiles/.config/fish/ ~/.config
