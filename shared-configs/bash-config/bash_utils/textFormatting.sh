#!/bin/bash

# This file generates formatted text, as described here:
# https://askubuntu.com/questions/528928/how-to-do-underline-bold-italic-strikethrough-color-background-and-size-i

_getFormattingCode() {
  local rule=$1
  case $rule in
  italic) echo "3" ;;
  bold) echo "1" ;;
  dim) echo "2" ;;
  blue) echo "34" ;;
  red) echo "31" ;;
  green) echo "32" ;;
  # Fallback to normal text formatting
  *) echo "0" ;;
  esac
}

_format() {
  local formattedStr=""
  local strToFormat=$1

  for key in "${@:2}"; do # All passed arguments starting at index 2
    formattedStr+="\e[$(_getFormattingCode "$key")m"
  done

  formattedStr+="$strToFormat"
  formattedStr+="\e[0m"

  echo "$formattedStr"
}

_echoAnnouncement() {
  local txt=$1
  # shellcheck disable=2059
  printf "$(_format "$txt" bold blue)\n"
}

_echoError() {
  local txt=$1
  # shellcheck disable=2059
  printf "$(_format "$txt" bold red)\n"
}
