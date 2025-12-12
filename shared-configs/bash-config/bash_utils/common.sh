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
    if [[ $arg == "$term" ]]; then return 0; fi
  done
  return 1
}
export -f _has_param

# https://superuser.com/questions/552600/how-can-i-find-the-oldest-file-in-a-directory-tree
alias oldest="find . -type f -print0 | xargs -0 ls -ltr | head -n 10"

# Delete function with confirmation, thanks ChatGPT!
del() {
  local target="$1"
  local files_count=0
  local dirs_count=0

  if [ -d "$target" ]; then
    files_count=$(find "$target" -type f | wc -l)
    dirs_count=$(find "$target" -mindepth 1 -type d | wc -l)
    ((dirs_count++)) # Account for the root directory itself
  elif [ -f "$target" ]; then
    files_count=1
  else
    echo "Error: '$target' is neither a file nor a directory"
    return 1
  fi

  # Display the count of files and directories to be deleted
  if [ "$dirs_count" -eq 0 ]; then
    echo "Deleting file '$target'"
  else
    echo "Deleting $files_count files and $dirs_count directories in '$target'"
  fi

  # Ask for confirmation
  # shellcheck disable=SC2162
  read -p "Are you sure you want to delete? [y/N] " response

  # Check the user's response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    # User confirmed, proceed with deletion
    rm -rf "$target"
    echo "Deleted '$target'"
  else
    # User canceled, exit without deleting
    echo "Deletion canceled"
  fi
}

# Kill whatever is running on input port
killport() {
  if [[ $# -eq 0 ]]; then
    echo "Provide at least one port value"
    return 1
  fi

  for port in "$@"; do
    local pids
    pids=$(lsof -ti:"$port")
    if [ -n "$pids" ]; then
      echo "$pids" | while read -r pid; do
        kill -9 "$pid"
        echo "Process $pid running on port $port has been killed."
      done
    else
      echo "No process on port $port"
    fi
  done
}

# Check if port is in use or not
checkport() {
  port=$1
  pid=$(lsof -ti:"$port")
  if [ -n "$pid" ]; then
    _portdetails "$port"
    return
  else
    echo "Port $port is not in use."
  fi
}

# Echo details about requested port
_portdetails() {
  port=$1
  lsof -i:"$port"
}

path() {
  i=1; IFS=: read -ra p <<< "$PATH"; for x in "${p[@]}"; do printf "%2d  %s\n" "$i" "$x"; ((i++)); done
}