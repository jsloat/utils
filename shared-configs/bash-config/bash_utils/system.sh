#!/bin/bash

# Configure this to point to the directory containing the utils repo
UTILS_REPO_PATH="$HOME/Dev/utils"

_pull_latest_shell_config() {
  _echoAnnouncement 'Pulling latest settings from GitHub'
  local INIT_DIR
  INIT_DIR=$(pwd)
  cd "$UTILS_REPO_PATH" || exit
  git pull --ff-only
  cd "$INIT_DIR" || exit
}

_reload_current_shell() {
  if [[ -n ${ZSH_VERSION:-} ]]; then
    _echoAnnouncement 'Reloading zsh session'
    # shellcheck disable=SC1090
    source "$HOME/.zshrc"
  else
    _echoAnnouncement 'Reloading bash session'
    # shellcheck disable=SC1090
    source "$HOME/.bashrc"
  fi
}

# shellcheck disable=2139
alias settings="code $UTILS_REPO_PATH"

shell_reload() {
  _reload_current_shell
}

shell_update() {
  local shell_target="both"
  if ! _has_param "--local" "$@"; then
    _pull_latest_shell_config
  fi
  bash "$UTILS_REPO_PATH/install.sh" --shell "$shell_target"
  _reload_current_shell
  _echoAnnouncement "Done"
}

reload() {
  _echoAnnouncement "Use 'shell_reload' instead."
  shell_reload
}

reload_session() {
  _echoAnnouncement "Use 'shell_reload' instead."
  shell_reload
}

# Use flag --local to skip pulling latest from master
refresh() {
  if [[ ${1:-} == 'local' ]]; then
    echo "Use --local flag instead"
    return 1
  fi
  _echoAnnouncement "Use 'shell_update' instead."
  shell_update "$@"
}
