#!/bin/bash

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)

require_command() {
  local cmd=$1
  local install_hint=$2
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$cmd" >&2
    printf '%s\n' "$install_hint" >&2
    exit 1
  fi
}

log() {
  printf '==> %s\n' "$1"
}

require_command shellcheck "Install it with: brew install shellcheck"
require_command zsh "zsh is required for zsh smoke tests."

TMP_HOME=$(mktemp -d)
trap 'rm -rf "$TMP_HOME"' EXIT

cd "$REPO_ROOT"

log "Running ShellCheck"
shellcheck \
  install.sh \
  scripts/deploy-shell-config.sh \
  bash/bash_profile \
  bash/bashrc \
  shared/common.sh \
  shared/path.sh \
  shared/system.sh \
  shared/textFormatting.sh \
  shared/git.sh \
  shared/macOS.sh \
  shared/gpt.sh \
  local/private.example.sh \
  local/secrets.example.sh

log "Checking zsh syntax"
zsh -n zsh/zprofile zsh/zshrc

log "Checking installer dry-run"
bash ./install.sh --dry-run --shell both >/tmp/utils-shell-install-dry-run.out

log "Checking shared helper sourcing in bash"
bash -lc '
  cd "'"$REPO_ROOT"'"
  export UTILS_REPO_PATH="'"$REPO_ROOT"'"
  source "'"$REPO_ROOT"'/shared/textFormatting.sh"
  source "'"$REPO_ROOT"'/shared/common.sh"
  source "'"$REPO_ROOT"'/shared/path.sh"
  source "'"$REPO_ROOT"'/shared/macOS.sh"
  source "'"$REPO_ROOT"'/shared/git.sh"
  source "'"$REPO_ROOT"'/shared/system.sh"
  source "'"$REPO_ROOT"'/shared/gpt.sh"
  PATH="/bin:/usr/bin"
  mkdir -p /tmp/utils-test-path-prepend /tmp/utils-test-path-append
  add_to_path /tmp/utils-test-path-prepend
  [[ "$PATH" == "/tmp/utils-test-path-prepend:/bin:/usr/bin" ]]
  add_to_path /tmp/utils-test-path-prepend
  [[ "$PATH" == "/tmp/utils-test-path-prepend:/bin:/usr/bin" ]]
  append_to_path /tmp/utils-test-path-append
  [[ "$PATH" == "/tmp/utils-test-path-prepend:/bin:/usr/bin:/tmp/utils-test-path-append" ]]
  [[ "$(_getFormattingCode green)" == "32" ]]
  [[ "$(_format hello bold)" == *hello* ]]
  declare -F _has_param >/dev/null
  _has_param foo bar foo
  ! _has_param foo bar baz
  declare -F is_terminal >/dev/null
  TERM_PROGRAM=Apple_Terminal
  is_terminal
  TERM_PROGRAM=vscode
  declare -F is_vscode >/dev/null
  is_vscode
  declare -F getBranchName >/dev/null
  test -n "$(getBranchName)"
  declare -F shell_reload >/dev/null
  declare -F shell_update >/dev/null
  declare -F gpt >/dev/null
  declare -F jeeves >/dev/null
  shell_update --local --dry-run >/tmp/utils-shell-update-dry-run-bash.out
  alias freshen >/dev/null
  alias loc >/dev/null
  path | head -1 | grep -Eq "^[[:space:]]*[0-9]+[[:space:]]+/"
'

log "Checking shared helper sourcing in zsh"
zsh -fc '
  cd "'"$REPO_ROOT"'"
  export UTILS_REPO_PATH="'"$REPO_ROOT"'"
  source "'"$REPO_ROOT"'/shared/textFormatting.sh"
  source "'"$REPO_ROOT"'/shared/common.sh"
  source "'"$REPO_ROOT"'/shared/path.sh"
  source "'"$REPO_ROOT"'/shared/macOS.sh"
  source "'"$REPO_ROOT"'/shared/git.sh"
  source "'"$REPO_ROOT"'/shared/system.sh"
  source "'"$REPO_ROOT"'/shared/gpt.sh"
  PATH="/bin:/usr/bin"
  mkdir -p /tmp/utils-test-path-prepend /tmp/utils-test-path-append
  add_to_path /tmp/utils-test-path-prepend
  [[ "$PATH" == "/tmp/utils-test-path-prepend:/bin:/usr/bin" ]]
  add_to_path /tmp/utils-test-path-prepend
  [[ "$PATH" == "/tmp/utils-test-path-prepend:/bin:/usr/bin" ]]
  append_to_path /tmp/utils-test-path-append
  [[ "$PATH" == "/tmp/utils-test-path-prepend:/bin:/usr/bin:/tmp/utils-test-path-append" ]]
  [[ "$(_getFormattingCode green)" == "32" ]]
  [[ "$(_format hello bold)" == *hello* ]]
  whence _has_param >/dev/null
  _has_param foo bar foo
  ! _has_param foo bar baz
  whence is_terminal >/dev/null
  TERM_PROGRAM=Apple_Terminal
  is_terminal
  TERM_PROGRAM=vscode
  whence is_vscode >/dev/null
  is_vscode
  whence getBranchName >/dev/null
  [[ -n "$(getBranchName)" ]]
  whence shell_reload >/dev/null
  whence shell_update >/dev/null
  whence gpt >/dev/null
  whence jeeves >/dev/null
  shell_update --local --dry-run >/tmp/utils-shell-update-dry-run-zsh.out
  alias freshen >/dev/null
  alias loc >/dev/null
  path | head -1 | grep -Eq "^[[:space:]]*[0-9]+[[:space:]]+/"
'

log "Checking deploy dry-run path without side effects"
DEPLOY_DRY_RUN=1 npm run deploy >/tmp/utils-shell-deploy-dry-run.out

log "Checking fresh bash session startup"
ln -s "$REPO_ROOT/bash/bash_profile" "$TMP_HOME/.bash_profile"
ln -s "$REPO_ROOT/bash/bashrc" "$TMP_HOME/.bashrc"
HOME="$TMP_HOME" bash -ilc '
  [[ "${UTILS_REPO_PATH:-}" == "'"$REPO_ROOT"'" ]]
  declare -F shell_reload >/dev/null
  declare -F shell_update >/dev/null
  if [[ -f /tmp/utils-current-path-baseline ]]; then
    current_path=$(cat /tmp/utils-current-path-baseline)
    [[ "$PATH" == "$current_path" ]]
  fi
  if [[ -f /tmp/utils-tdk-status ]] && [[ $(cat /tmp/utils-tdk-status) == "tdk-present" ]]; then
    command -v tdk >/dev/null
  fi
' >/tmp/utils-bash-fresh.out 2>/tmp/utils-bash-fresh.err

log "Checking fresh zsh session startup"
ln -s "$REPO_ROOT/zsh/zprofile" "$TMP_HOME/.zprofile"
ln -s "$REPO_ROOT/zsh/zshrc" "$TMP_HOME/.zshrc"
HOME="$TMP_HOME" zsh -ilc '
  [[ "${UTILS_REPO_PATH:-}" == "'"$REPO_ROOT"'" ]]
  whence shell_reload >/dev/null
  whence shell_update >/dev/null
  if [[ -f /tmp/utils-current-path-baseline ]]; then
    current_path=$(cat /tmp/utils-current-path-baseline)
    [[ "$PATH" == "$current_path" ]]
  fi
  if [[ -f /tmp/utils-tdk-status ]] && [[ $(cat /tmp/utils-tdk-status) == "tdk-present" ]]; then
    command -v tdk >/dev/null
  fi
' >/tmp/utils-zsh-fresh.out 2>/tmp/utils-zsh-fresh.err

log "Shell smoke tests passed"
