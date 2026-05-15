#!/bin/bash

# Copy this file to local/private.sh for machine-specific shell helpers.

if [ -e "${UTILS_REPO_PATH:-$HOME/Dev/utils}/local/path.sh" ]; then
  # shellcheck disable=SC1091
  source "${UTILS_REPO_PATH:-$HOME/Dev/utils}/local/path.sh"
fi

if [ -e "${UTILS_REPO_PATH:-$HOME/Dev/utils}/local/secrets.sh" ]; then
  # shellcheck disable=SC1091
  source "${UTILS_REPO_PATH:-$HOME/Dev/utils}/local/secrets.sh"
fi

# Optional machine-local help entries live in local/halp.txt.
#
# Example entry:
# mymachine|Run my personal machine-specific helper
#
# Example machine-local additions:
# export SOME_TOOL_HOME="$HOME/somewhere"
# NVM_SCRIPT="/opt/homebrew/opt/nvm/nvm.sh"
# _load_nvm_impl() { source "$NVM_SCRIPT"; }
# define_lazy_function nvm _load_nvm_impl
# alias mymachine="echo hello"
