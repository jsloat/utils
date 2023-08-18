#!/bin/bash

MAIN_BRANCH_NAME=${OVERRIDE_MAIN_BRANCH_NAME:-master}

# Get current branch name
getBranchName() {
  local branch
  branch=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')
  echo "$branch"
}

# "Project keys must start with an uppercase letter, followed by one or more
#   uppercase alphanumeric characters"
getJiraKey() {
  local branchName=$1
  local REGEX_ISSUE_ID="^[A-Z][A-Z\d]{1,}-\d+"
  key=$(getBranchName | grep -o -E "$REGEX_ISSUE_ID")
  echo "$key"
}

pushup() {
  git push -u origin "$(getBranchName)"
}

# Create a new branch of master locally, then push it to origin
newbr() {
  local branchName=$1
  local prefix=$2
  if [[ $# -eq 0 ]]; then
    echo "Provide branch name"
    return 1
  fi
  local prefixedBranchName="$prefix$branchName"
  git checkout "$MAIN_BRANCH_NAME"
  git fetch
  git reset --hard origin/"$MAIN_BRANCH_NAME"
  git checkout -b "$prefixedBranchName"
  git push -u origin "$prefixedBranchName"
}

# Unstages the last N commits in the branch
goback() {
  local num=$1
  git reset HEAD~"$num"
}

# Git branch
gb() {
  local query
  local branchPattern
  local opts
  local currBranch
  local raw_branches_str
  local OLD_IFS
  local raw_branches_arr
  query=$1
  branchPattern="refs/heads/"$([ $# -eq 0 ] && echo '' || echo "**/*$query*")
  opts=()
  currBranch=$(getBranchName)

  raw_branches_str=$(git for-each-ref --format='%(refname:short)' "$branchPattern" --ignore-case)
  # https://stackoverflow.com/questions/24628076/convert-multiline-string-to-array
  OLD_IFS=$IFS
  IFS=$'\n'
  # shellcheck disable=2206
  raw_branches_arr=($raw_branches_str)
  IFS=$OLD_IFS

  # https://stackoverflow.com/questions/3578584/bash-how-to-delete-elements-from-an-array-based-on-a-pattern
  for index in "${!raw_branches_arr[@]}"; do
    local brName=${raw_branches_arr[$index]}
    if [[ $brName != "$currBranch" ]]; then opts+=("$brName"); fi
  done

  local optsLen=${#opts[@]}
  case $optsLen in
  0) _echoError "No branches found" ;;
  1) git checkout "${opts[0]}" ;;
  *) select branch in "${opts[@]}"; do
    git checkout "$branch"
    break
  done ;;
  esac
}

# First param is command (push or push-force)
# Optional --force flag to force push on master branch.
_runGitCommandWithMasterProtection() {
  local commandKey=$1
  local br
  br=$(getBranchName)
  if [[ $br == "$MAIN_BRANCH_NAME" ]] && ! _has_param "--force" "$@"; then
    _echoError "Use '--force' flag to perform this operation on master. Are you on the correct branch?"
    return 1
  fi

  case $commandKey in
  push) git push ;;
  push-force) git push --force-with-lease ;;
  *) _echoError "Invalid command" ;;
  esac

}

# Guarded git push, optional --force flag
gp() {
  if _has_param "--force" "$@"; then
    _runGitCommandWithMasterProtection push --force
  else
    _runGitCommandWithMasterProtection push
  fi
}

# Guarded git push force, optional --force flag
gpf() {
  if _has_param "--force" "$@"; then
    _runGitCommandWithMasterProtection push-force --force
  else
    _runGitCommandWithMasterProtection push-force
  fi
}

# Git branches sorted by last updated (locally)
gbsort() {
  git for-each-ref --sort='-authordate:iso8601' --format=' %(authordate:relative)%09%(refname:short)' refs/heads
}

orphans() {
  _echoAnnouncement "Branches without remote counterparts:"
  git branch --format "%(refname:short) %(upstream)" | awk '{if (!$2) print $1;}'
}

getHeadCommitSHA() {
  local sha
  sha=$(git rev-parse --verify HEAD)
  echo "$sha"
}

alias gc-='git checkout -'
alias gm-='git merge -'
alias grim='git rebase -i $MAIN_BRANCH_NAME'
alias gcwip='git add -A;git commit -m "wip"'
alias gst='git status'
alias sup='git fetch &> /dev/null;gst'
# shellcheck disable=2139
alias gcm="git checkout $MAIN_BRANCH_NAME"
alias gl='git pull'
# Fetch latest master, then interactive rebase on it
alias fgrim='gcm &> /dev/null;gl &> /dev/null;gc- &> /dev/null;grim'
# Switch to master then delete previous local branch
alias gdel='gcm &> /dev/null;git branch -D @{-1}'
# Reset hard to remote branch
alias rerem='git reset --hard origin/$(getBranchName)'
# Reset hard to previous local branch
alias relast='git reset --hard @{-1}'
alias glol="git log --pretty='%C(bold blue)%<(10,trunc)%an%Creset %Cgreen%<(10,trunc)%cr%Creset %C(auto)%<(57,trunc)%s%Creset'"
alias freshen='git pull --rebase origin $MAIN_BRANCH_NAME'
alias amend='git add .;git commit --amend'
alias lastcommit='git log -1 --pretty=%B | cat'
# Show LOC change stats for current branch compared to main branch.
alias loc="git fetch &> /dev/null;git diff --shortstat origin/$MAIN_BRANCH_NAME"
