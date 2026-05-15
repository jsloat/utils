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
  local format_rule

  for format_rule in "${@:2}"; do
    formattedStr+="\e[$(_getFormattingCode "$format_rule")m"
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
