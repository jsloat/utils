#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
DEFAULT_SHELL="both"
DRY_RUN=false
FORCE=false
TARGET_SHELL="$DEFAULT_SHELL"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
ANTIDOTE_DIR="$HOME/.antidote"

usage() {
  cat <<'EOF'
Usage: bash ./install.sh [--shell bash|zsh|both] [--dry-run] [--force]

Creates symlinks for shell startup files:
  bash -> ~/.bash_profile, ~/.bashrc
  zsh  -> ~/.zprofile, ~/.zshrc

Options:
  --shell    Which shell targets to wire. Default: both
  --dry-run  Print actions without changing files
  --force    Replace unexpected existing symlinks
  --help     Show this help message
EOF
}

log() {
  printf '%s\n' "$1"
}

run_cmd() {
  if $DRY_RUN; then
    printf '[dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

resolve_existing_path() {
  local src=$1
  while [ -L "$src" ]; do
    local dir
    dir=$(cd -P "$(dirname "$src")" && pwd)
    src=$(readlink "$src")
    if [[ $src != /* ]]; then
      src="$dir/$src"
    fi
  done
  local base
  base=$(basename "$src")
  printf '%s/%s\n' "$(cd -P "$(dirname "$src")" && pwd)" "$base"
}

backup_target() {
  local target=$1
  local backup="${target}.pre-shell-config.${TIMESTAMP}"
  log "Backing up $target -> $backup"
  run_cmd mv "$target" "$backup"
}

ensure_link() {
  local source=$1
  local target=$2

  if [ ! -e "$source" ]; then
    printf 'Missing source file: %s\n' "$source" >&2
    exit 1
  fi

  if [ -L "$target" ]; then
    local current_resolved
    local expected_resolved
    current_resolved=$(resolve_existing_path "$target")
    expected_resolved=$(resolve_existing_path "$source")

    if [ "$current_resolved" = "$expected_resolved" ]; then
      log "OK: $target already points to $source"
      return 0
    fi

    if ! $FORCE; then
      printf 'Refusing to replace unexpected symlink: %s\n' "$target" >&2
      printf 'Re-run with --force if you want to replace it.\n' >&2
      exit 1
    fi

    log "Replacing unexpected symlink: $target"
    run_cmd rm "$target"
  elif [ -e "$target" ]; then
    backup_target "$target"
  fi

  log "Linking $target -> $source"
  run_cmd ln -s "$source" "$target"
}

ensure_antidote() {
  if [ -f "$ANTIDOTE_DIR/antidote.zsh" ]; then
    log "OK: antidote already present at $ANTIDOTE_DIR"
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    printf 'git is required to bootstrap antidote for zsh.\n' >&2
    exit 1
  fi

  log "Installing antidote -> $ANTIDOTE_DIR"
  run_cmd git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_DIR"
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --shell)
        if [ $# -lt 2 ]; then
          printf 'Missing value for --shell\n' >&2
          exit 1
        fi
        TARGET_SHELL=$2
        shift 2
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --force)
        FORCE=true
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        printf 'Unknown argument: %s\n' "$1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  case "$TARGET_SHELL" in
    bash|zsh|both) ;;
    *)
      printf 'Invalid shell target: %s\n' "$TARGET_SHELL" >&2
      exit 1
      ;;
  esac
}

link_bash() {
  ensure_link "$SCRIPT_DIR/bash/bash_profile" "$HOME/.bash_profile"
  ensure_link "$SCRIPT_DIR/bash/bashrc" "$HOME/.bashrc"
}

link_zsh() {
  ensure_antidote
  ensure_link "$SCRIPT_DIR/zsh/zprofile" "$HOME/.zprofile"
  ensure_link "$SCRIPT_DIR/zsh/zshrc" "$HOME/.zshrc"
}

parse_args "$@"

case "$TARGET_SHELL" in
  bash)
    link_bash
    ;;
  zsh)
    link_zsh
    ;;
  both)
    link_bash
    link_zsh
    ;;
esac

log ""
log "Install complete."
log "You can re-run this installer safely with: bash ./install.sh --shell both"
if $DRY_RUN; then
  log "Dry run only: no files were changed."
fi
