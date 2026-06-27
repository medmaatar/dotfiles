#!/bin/bash

# This is the setup script for my config. The idea is to be able to run
# this after cloning the repo on a Mac or Ubuntu (WSL) system and be up
# and running very quickly.

# create directories
export XDG_CONFIG_HOME="$HOME"/.config
mkdir -p "$XDG_CONFIG_HOME"/tmux/plugins
# set up git prompt
# curl -L htps://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh >"$XDG_CONFIG_HOME"/bash/git-prompt.sh

# Symbolic links

# ln -s ./.amethyst.yml "$HOME"/.amethyst.yml
ln -sf "$PWD/.zshrc" "$HOME"/.zshrc
ln -sf "$PWD/.inputrc" "$HOME"/.inputrc
ln -sf "$PWD/.tmux.conf" "$XDG_CONFIG_HOME"/tmux/.tmux.conf
ln -sf "$PWD/nvim" "$XDG_CONFIG_HOME"/nvim
ln -sf "$PWD/.p10k.zsh" "$XDG_CONFIG_HOME"/.p10k.zsh
ln -sf "$PWD/scripts" "$XDG_CONFIG_HOME"/scripts
ln -sf "$PWD/powerlevel10k" "$HOME"/powerlevel10k
ln -sf "$PWD/polybar" "$XDG_CONFIG_HOME"/polybar
ln -sf "$PWD/i3" "$XDG_CONFIG_HOME"/i3
# set up blog
# git clone git@github.com:mischavandenburg/hugo-PaperModX-theme.git themes/PaperModX --depth=1
# Give permissions to the scripts
chmod +x "$PWD"/scripts/*
# Packages

mkdir -p $SECOND_BRAIN

if ! command -v node &> /dev/null; then
    curl -sL https://deb.nodesource.com/setup_18.x -o nodesource_setup.sh
    sudo bash nodesource_setup.sh
    sudo apt install nodejs
fi
