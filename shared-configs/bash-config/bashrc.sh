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
export PS1="\[\033[32m\]\w\$(_prettify_git_branch)\[\033[00m\]: "

export PATH="/usr/local/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && \. "/usr/local/opt/nvm/nvm.sh"                                       # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/usr/local/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion
