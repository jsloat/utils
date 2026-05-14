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

cd "$REPO_ROOT"

log "Running ShellCheck"
shellcheck \
  install.sh \
  scripts/deploy-shell-config.sh \
  bash/bash_profile \
  bash/bashrc \
  shared-configs/bash-config/bash_profile.sh \
  shared-configs/bash-config/bashrc.sh \
  shared-configs/bash-config/bash_utils/common.sh \
  shared-configs/bash-config/bash_utils/system.sh \
  shared-configs/bash-config/bash_utils/textFormatting.sh \
  shared-configs/bash-config/bash_utils/git.sh \
  shared-configs/bash-config/bash_utils/macOS.sh \
  shared-configs/bash-config/bash_utils/gpt.sh

log "Checking zsh syntax"
zsh -n zsh/zprofile zsh/zshrc

log "Checking installer dry-run"
bash ./install.sh --dry-run --shell both >/tmp/utils-shell-install-dry-run.out

log "Checking shared helper sourcing in bash"
bash -lc '
  source "'"$REPO_ROOT"'/shared-configs/bash-config/bash_utils/textFormatting.sh"
  source "'"$REPO_ROOT"'/shared-configs/bash-config/bash_utils/common.sh"
  source "'"$REPO_ROOT"'/shared-configs/bash-config/bash_utils/system.sh"
  declare -F _has_param >/dev/null
  declare -F shell_reload >/dev/null
  declare -F shell_update >/dev/null
'

log "Checking shared helper sourcing in zsh"
zsh -fc '
  source "'"$REPO_ROOT"'/shared-configs/bash-config/bash_utils/textFormatting.sh"
  source "'"$REPO_ROOT"'/shared-configs/bash-config/bash_utils/common.sh"
  source "'"$REPO_ROOT"'/shared-configs/bash-config/bash_utils/system.sh"
  whence _has_param >/dev/null
  whence shell_reload >/dev/null
  whence shell_update >/dev/null
'

log "Checking deploy dry-run path without side effects"
DEPLOY_DRY_RUN=1 npm run deploy >/tmp/utils-shell-deploy-dry-run.out

log "Shell smoke tests passed"
