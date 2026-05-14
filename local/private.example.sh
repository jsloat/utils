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

# Example machine-local additions:
# export SOME_TOOL_HOME="$HOME/somewhere"
# alias mymachine="echo hello"
