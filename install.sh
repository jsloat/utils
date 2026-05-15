#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
DEFAULT_SHELL="both"
DRY_RUN=false
FORCE=false
TARGET_SHELL="$DEFAULT_SHELL"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
ANTIDOTE_DIR="$HOME/.antidote"
FONT_DIRS_DEFAULT="$HOME/Library/Fonts:/Library/Fonts"
COLOR_RESET=""
COLOR_GREEN=""
COLOR_RED=""

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  COLOR_RESET=$'\033[0m'
  COLOR_GREEN=$'\033[32m'
  COLOR_RED=$'\033[31m'
fi

log() {
  printf '%s\n' "$1"
}

log_ok() {
  printf '%b\n' "${COLOR_GREEN}$1${COLOR_RESET}"
}

log_warn() {
  printf '%b\n' "${COLOR_RED}$1${COLOR_RESET}"
}

log_error() {
  printf '%b\n' "${COLOR_RED}$1${COLOR_RESET}" >&2
}

warn_if_fzf_missing() {
  if ! command -v fzf >/dev/null 2>&1; then
    log_warn "Warning: fzf is not installed. fzf-tab is configured in zsh/plugins.txt, so tab completion UI may degrade until you run: brew install fzf"
  fi
}

has_recommended_nerd_font() {
  local font_dirs dir
  font_dirs=${SHELL_CONFIG_FONT_DIRS:-$FONT_DIRS_DEFAULT}

  IFS=':' read -r -a font_dirs_array <<<"$font_dirs"
  for dir in "${font_dirs_array[@]}"; do
    if [ -d "$dir" ] && find "$dir" -maxdepth 1 -type f \( -iname 'MesloLG*NF*.ttf' -o -iname 'MesloLG*NerdFont*.ttf' \) | grep -q .; then
      return 0
    fi
  done

  return 1
}

warn_if_font_missing() {
  if ! has_recommended_nerd_font; then
    log_warn "Warning: the zsh prompt uses Nerd Font glyphs. Install MesloLGS NF with: brew install --cask font-meslo-lg-nerd-font"
    log "Then set Terminal.app > Settings > Profiles > Text > Font to MesloLGS NF."
  fi
}

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

ensure_file() {
  local target=$1

  if [ -e "$target" ]; then
    return 0
  fi

  log "Creating $target"
  run_cmd touch "$target"
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
    log_error "Missing source file: $source"
    exit 1
  fi

  if [ -L "$target" ]; then
    local current_resolved
    local expected_resolved
    current_resolved=$(resolve_existing_path "$target")
    expected_resolved=$(resolve_existing_path "$source")

    if [ "$current_resolved" = "$expected_resolved" ]; then
      log_ok "OK: $target already points to $source"
      return 0
    fi

    if ! $FORCE; then
      log_error "Refusing to replace unexpected symlink: $target"
      log_error "Re-run with --force if you want to replace it."
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
    log_ok "OK: antidote already present at $ANTIDOTE_DIR"
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    log_error "git is required to bootstrap antidote for zsh."
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
          log_error "Missing value for --shell"
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
        log_error "Unknown argument: $1"
        usage >&2
        exit 1
        ;;
    esac
  done

  case "$TARGET_SHELL" in
    bash|zsh|both) ;;
    *)
      log_error "Invalid shell target: $TARGET_SHELL"
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
  warn_if_fzf_missing
  warn_if_font_missing
  ensure_link "$SCRIPT_DIR/zsh/zprofile" "$HOME/.zprofile"
  ensure_link "$SCRIPT_DIR/zsh/zshrc" "$HOME/.zshrc"
}

parse_args "$@"
ensure_file "$HOME/.hushlogin"

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
log_ok "Install complete."
log "You can re-run this installer safely with: bash ./install.sh --shell both"
if $DRY_RUN; then
  log "Dry run only: no files were changed."
fi
