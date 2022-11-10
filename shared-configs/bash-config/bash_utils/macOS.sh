#!/bin/bash

alias open_terminal="osascript -e 'tell application \"Terminal\" to activate'"

alias new_terminal_window="osascript -e 'tell application \"System Events\" to tell process \"Terminal\" to keystroke \"n\" using command down'"

alias new_terminal_tab="osascript -e 'tell application \"System Events\" to tell process \"Terminal\" to keystroke \"t\" using command down'"

is_terminal() {
  if [[ $TERM_PROGRAM == 'Apple_Terminal' ]]; then return 0; else return 1; fi
}

is_vscode() {
  if [[ $TERM_PROGRAM == 'vscode' ]]; then return 0; else return 1; fi
}

# --in_new_tab    Run the command in a new terminal tab
run_in_front_terminal() {
  if [[ $# -eq 0 ]]; then
    echo "run_in_front_terminal requires an argument"
    return 1
  fi
  if _has_param "--in_new_tab" "$@"; then new_terminal_tab; fi
  osascript -e "tell application \"Terminal\" to do script \"$1;\" in selected tab of the front window"
}
