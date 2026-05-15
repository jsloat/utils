#!/bin/bash

UTILS_REPO_PATH=${UTILS_REPO_PATH:-"$HOME/Dev/utils"}
ZSH_PLUGIN_FILE="$UTILS_REPO_PATH/zsh/plugins.txt"
ANTIDOTE_DIR="$HOME/.antidote"
HALP_FILE="$UTILS_REPO_PATH/shared/halp.txt"
LOCAL_HALP_FILE="$UTILS_REPO_PATH/local/halp.txt"

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
    # shellcheck disable=SC1090,SC1091
    source "$HOME/.zshrc"
  else
    _echoAnnouncement 'Reloading bash session'
    # shellcheck disable=SC1090,SC1091
    source "$HOME/.bashrc"
  fi
}

# shellcheck disable=2139
alias settings="code $UTILS_REPO_PATH"

shell_reload() {
  _reload_current_shell
}

shell_update() {
  if _has_param "--dry-run" "$@"; then
    if ! _has_param "--local" "$@"; then
      _echoAnnouncement "Dry run: would pull latest settings from GitHub."
    fi
    _echoAnnouncement "Dry run only: shell was not reloaded."
    return 0
  fi

  if ! _has_param "--local" "$@"; then
    _pull_latest_shell_config
  fi

  _reload_current_shell
  _echoAnnouncement "Done"
}

_print_halp_entries() {
  local file=$1
  if [[ ! -f "$file" ]]; then
    return 0
  fi

  while IFS='|' read -r command description; do
    if [[ -z ${command:-} ]] || [[ ${command:0:1} == '#' ]]; then
      continue
    fi
    printf '%s|%s\n' "$command" "$description"
  done <"$file"
}

halp() {
  printf '\n'
  printf '%s\n' "$(_format "halp" bold blue)"
  printf '%s\n' "$(_format "------------------------------" dim)"

  {
    _print_halp_entries "$HALP_FILE"
    _print_halp_entries "$LOCAL_HALP_FILE"
  } | LC_ALL=C sort -t'|' -k1,1 | while IFS='|' read -r command description; do
    printf '  %s  %s\n' \
      "$(_format "$(printf '%-28s' "$command")" bold green)" \
      "$(_format "$description" dim)"
  done

  printf '\n'
}

zsh_plugins_edit() {
  if command -v code >/dev/null 2>&1; then
    code "$ZSH_PLUGIN_FILE"
  else
    printf '%s\n' "$ZSH_PLUGIN_FILE"
  fi
}

zsh_plugins_update() {
  if [[ ! -f "$ZSH_PLUGIN_FILE" ]]; then
    _echoError "Missing zsh plugin file: $ZSH_PLUGIN_FILE"
    return 1
  fi

  if [[ ! -f "$ANTIDOTE_DIR/antidote.zsh" ]]; then
    _echoError "antidote is not installed. Run: bash \"$UTILS_REPO_PATH/install.sh\" --shell zsh"
    return 1
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    _echoAnnouncement "fzf is not installed. fzf-tab is configured, so install it with: brew install fzf"
  fi

  _echoAnnouncement "Updating zsh plugins from $ZSH_PLUGIN_FILE"
  zsh -ic "source \"$ANTIDOTE_DIR/antidote.zsh\" && antidote update"

  if [[ -n ${ZSH_VERSION:-} ]]; then
    _echoAnnouncement "Reloading zsh session"
    # shellcheck disable=SC1090,SC1091
    source "$HOME/.zshrc"
  else
    _echoAnnouncement "Done. Reload zsh to pick up plugin changes."
  fi
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
