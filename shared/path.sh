#!/bin/bash

path_has() {
  local dir=$1
  case ":$PATH:" in
  *":$dir:"*) return 0 ;;
  *) return 1 ;;
  esac
}

add_to_path() {
  local dir=$1
  if [ -d "$dir" ] && ! path_has "$dir"; then
    export PATH="$dir:$PATH"
  fi
}

append_to_path() {
  local dir=$1
  if [ -d "$dir" ] && ! path_has "$dir"; then
    export PATH="$PATH:$dir"
  fi
}

add_to_path "/usr/local/bin"
