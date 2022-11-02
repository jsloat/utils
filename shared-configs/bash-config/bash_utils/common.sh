#!/bin/bash

openUrl() {
  local url=$1
  /usr/bin/open -a "/Applications/Brave Browser.app" "$url"
}

# Search contents of all files, recursively, from curr. location, finding those
# that contain the search query (case insensitive). Optionally also provide the
# directory to search from as 2nd argument
fsearch() {
  local query=$1
  local maybeDir=$2
  local dir
  dir=$([ $# -eq 2 ] && echo "$maybeDir" || echo '.')
  grep \
    --ignore-case \
    --recursive \
    --files-with-matches \
    "$query" "$dir" | sort | xargs wc -l
}

# ls helper
show() {
  # shellcheck disable=2010
  case $1 in
  'files') ls -al | grep '^-' ;;
  'all') ls -a ;;
  'folders') ls -d ./*/ ;;
  *) ls ;;
  esac
}

_has_param() {
  local term="$1"
  shift
  for arg; do
    if [[ $arg == "$term" ]]; then
      return 0
    fi
  done
  return 1
}
export -f _has_param
