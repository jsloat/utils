#!/bin/bash
# shellcheck disable=1090,1091

source ~/bash_utils/textFormatting.sh
source ~/bash_utils/common.sh
source ~/bash_utils/git.sh
source ~/bash_utils/system.sh
# Optional private source import for sensitive things.
if test -e ~/bash_utils/private.sh; then
  source ~/bash_utils/private.sh
fi

# https://stackoverflow.com/questions/17333531/how-can-i-display-the-current-branch-and-folder-path-in-terminal
_prettify_git_branch() {
  git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ [\1]/'
}
# Customizes the terminal prompt to show curr directory & git repo/branch (if any)
export PS1="\n\[\033[32m\]\w\n\$(_prettify_git_branch)\[\033[00m\]: "

export PATH="/usr/local/bin:$PATH"
