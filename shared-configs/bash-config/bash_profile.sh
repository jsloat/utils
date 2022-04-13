#!/bin/bash

# Ensure that all new terminal sessions load everything
# shellcheck disable=1091
source "$HOME"/.bashrc

# Silence the bash deprecation warning on terminal start
export BASH_SILENCE_DEPRECATION_WARNING=1

eval "$(/opt/homebrew/bin/brew shellenv)"
