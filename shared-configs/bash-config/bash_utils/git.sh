#!/bin/bash

# Get current branch name
getBranchName() {
  branch=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')
  echo "$branch"
}

getJiraKey() {
  local branchName=$1
  local REGEX_ISSUE_ID="[a-zA-Z0-9,\.\_\-]+-[0-9]+"
  # shellcheck disable=2046,2005
  echo $(getBranchName | grep -o -E "$REGEX_ISSUE_ID")
}

pushup() {
  git push -u origin "$(getBranchName)"
}

# Create a new branch of master locally, then push it to origin
newbr() {
  local branchName=$1
  git checkout master
  git fetch
  git reset --hard origin/master
  git checkout -b "$branchName"
  git push -u origin "$branchName"
}

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
  branchPattern="refs/heads/"$([ $# -eq 0 ] && echo '' || echo "*$query*")
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
    if [[ $brName != "$currBranch" ]]; then
      opts+=("$brName")
    fi
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

_runGitCommandWithMasterProtection() {
  # push | push-force
  local commandKey=$1
  local shouldForce=$2
  local br
  br=$(getBranchName)
  if [[ $br == "master" ]] && [[ $shouldForce != "force" ]]; then
    _echoError "Use 'force' argument to perform this operation on master. Are you on the correct branch?"
  else
    case $commandKey in
    push) git push ;;
    push-force) git push --force-with-lease ;;
    *) _echoError "Invalid command" ;;
    esac
  fi
}

# Guarded git push
gp() {
  local shouldForce=$1
  _runGitCommandWithMasterProtection push "$shouldForce"
}

# Guarded git push force
gpf() {
  local shouldForce=$1
  _runGitCommandWithMasterProtection push-force "$shouldForce"
}

# Git branches sorted by last updated (locally)
gbsort() {
  git for-each-ref --sort='-authordate:iso8601' --format=' %(authordate:relative)%09%(refname:short)' refs/heads
}

orphans() {
  _echoAnnouncement "Branches without remote counterparts:"
  git branch --format "%(refname:short) %(upstream)" | awk '{if (!$2) print $1;}'
}

alias gc-='git checkout -'
alias gm-='git merge -'
alias grim='git rebase -i master'
alias gcwip='git add -A;git commit -m "wip"'
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
# Reset hard to previous local branch
alias relast='git reset --hard @{-1}'
alias glol="git log --pretty='%C(bold blue)%<(10,trunc)%an%Creset %Cgreen%<(10,trunc)%cr%Creset %C(auto)%<(57,trunc)%s%Creset'"
alias freshen='git pull --rebase origin master'
alias amend='git add .;git commit --amend'
alias lastcommit='git log -1 --pretty=%B | cat'
