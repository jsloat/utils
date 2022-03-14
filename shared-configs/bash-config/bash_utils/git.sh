# Get current branch name
getBranchName() {
  branch=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')
  echo $branch
}

getJiraKey() {
  local branchName=$1
  local REGEX_ISSUE_ID="[a-zA-Z0-9,\.\_\-]+-[0-9]+"
  echo $(getBranchName | grep -o -E "$REGEX_ISSUE_ID")
}

# Create a new branch of master locally, then push it to origin
newbr() {
  local branchName=$1
  git checkout master
  git fetch
  git reset --hard origin/master
  git checkout -b $branchName
  git push -u origin $branchName
}

goback() {
  local num=$1
  git reset HEAD~$num
}

# Git branch
gb() {
  local query=$1
  local branchPattern="refs/heads/"$([ $# -eq 0 ] && echo '*-*' || echo "*$query*")
  local opts=()
  local raw_branches=$(git for-each-ref --format='%(refname:short)' "$branchPattern" --ignore-case)
  local currBranch=$(getBranchName)
  while read line; do if [[ $line != $currBranch ]]; then opts+=("$line"); fi; done < <($raw_branches)
  local optsLen=${#opts[@]}
  case $optsLen in
  0) echo "No branches found" ;;
  1) git checkout "$opts[1]" ;;
  *) select branch in "${opts[@]}"; do
    git checkout "$branch"
    break
  done ;;
  esac
}

_runGitCommandWithMasterProtection() {
  # push | push-force
  local commandKey=$1
  local shouldForce=$2
  local br=$(getBranchName)
  if [[ $br == "master" ]] && [[ $shouldForce != "force" ]]; then
    echo "Use 'force' argument to perform this operation on master. Are you on the correct branch?"
  else
    case $commandKey in
    push) git push ;;
    push-force) git push --force-with-lease ;;
    *) echo "Invalid command" ;;
    esac
  fi
}

# Guarded git push
gp() {
  local shouldForce=$1
  _runGitCommandWithMasterProtection push $shouldForce
}

# Guarded git push force
gpf() {
  local shouldForce=$1
  _runGitCommandWithMasterProtection push-force $shouldForce
}

# Git branches sorted by last updated (locally)
gbsort() {
  git for-each-ref --sort='-authordate:iso8601' --format=' %(authordate:relative)%09%(refname:short)' refs/heads
}

orphans() {
  echo "Branches without remote counterparts:"
  git branch --format "%(refname:short) %(upstream)" | awk '{if (!$2) print $1;}'
}

alias gc-='git checkout -'
alias gm-='git merge -'
alias grim='git rebase -i master'
alias gcwip='git add .;git commit -m "wip"'
alias gst='git status'
alias sup='git fetch;gst'
alias gcm='git checkout master'
alias gl='git pull'
# Fetch latest master, then interactive rebase on it
alias fgrim='gcm;gl;gc-;grim'
# Switch to master then delete previous local branch
alias gdel='gcm;git branch -D @{-1}'
# Reset hard to remote branch
alias rerem='git reset --hard origin/''$(getBranchName)'
