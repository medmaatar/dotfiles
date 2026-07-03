# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.

export GITUSER="maatarmed"
export REPOS="$HOME/Work"
export GHREPOS="$REPOS/github.com/$GITUSER"
export DOTFILES="$GHREPOS/dotfiles"
export SCRIPTS="$DOTFILES/scripts"
export SECOND_BRAIN="$GHREPOS/ZeeVault"
export EJ="$REPOS/github.com/eyesjapan"
export ALAN="$EJ/alan-pd-ml"


# if path does not exist, create it
if [ ! -d "$REPOS" ]; then
  mkdir -p $REPOS
fi
if [ ! -d "$GHREPOS" ]; then
  mkdir -p $GHREPOS
fi
if [ ! -d "$EJ" ]; then
  mkdir -p $EJ
fi
#second brain
if [ ! -d "$SECOND_BRAIN" ]; then
  mkdir -p $SECOND_BRAIN
fi
# alan
if [ ! -d "$ALAN" ]; then
  mkdir -p $ALAN
  # git clone git@github.com:eyesjapan/alan-pd-ml.git $ALAN
fi
############# PATH #############
PATH="${PATH:+${PATH}:}"$SCRIPTS"" # appending scripts to path
if [ -d "$HOME/anaconda3/" ]; then
  PATH="$HOME/anaconda3/bin:$PATH"
fi
if [ -d "$HOME/miniconda3/" ]; then
  PATH="$HOME/miniconda3/bin:$PATH"
fi
# PATH="$HOME/anaconda3/bin:$PATH"
# PATH="$HOME/miniconda3/bin:$PATH" # adding miniconda to path
# tmuxifier
export PATH="$HOME/.tmuxifier/bin:$PATH"
export PATH
alias v=nvim
alias ..="cd .."
alias scripts="cd $SCRIPTS"
alias repos="cd $REPOS"
alias ghrepos="cd $GHREPOS"
alias dot="cd $DOTFILES"
alias alan="cd $ALAN"
alias sb="cd $SECOND_BRAIN"
# finds all files recursively and sorts by last modification, ignore hidden files
alias last='find . -type f -not -path "*/\.*" -exec ls -lrt {} +'

alias t='tmux'
alias tm='tmuxifier'
# git
alias gp="git pull"
alias gs="git status"
alias lg="lazygit"
alias gc="git commit"

#sourcing
alias sbr='source ~/.bashrc'
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/maatar/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/maatar/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/maatar/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/maatar/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

. "$HOME/.local/share/../bin/env"

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
export PATH="/home/maatar/.config/herd-lite/bin:$PATH"
export PHP_INI_SCAN_DIR="/home/maatar/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"
. "$HOME/.cargo/env"
eval "$(tmuxifier init -)"
