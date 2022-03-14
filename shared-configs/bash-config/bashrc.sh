source ~/bash_utils/common.sh
source ~/bash_utils/git.sh
source ~/bash_utils/system.sh
# Optional private source import for sensitive things.
if test -e ~/bash_utils/private.sh; then
  source ~/bash_utils/private.sh
fi

# https://stackoverflow.com/questions/17333531/how-can-i-display-the-current-branch-and-folder-path-in-terminal
_prettify_git_branch() {
  git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# Customizes the terminal prompt to show curr directory & git repo/branch (if any)
export PS1="\u@\h \[\033[32m\]\w\$(_prettify_git_branch)\[\033[00m\] $ "

# Silences warning about default terminal being ZSH
export BASH_SILENCE_DEPRECATION_WARNING=1
