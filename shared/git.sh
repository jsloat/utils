#!/bin/bash

mainBranchName() {
  if typeset -f _getMainBranchName >/dev/null 2>&1; then
    _getMainBranchName
  else
    printf '%s\n' "master"
  fi
}

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

# Create a new branch of the repo's main branch locally, then push it to origin
newbr() {
  local branchName=$1
  local prefix=$2
  local main_branch
  if [[ $# -eq 0 ]]; then
    echo "Provide branch name"
    return 1
  fi
  main_branch=$(mainBranchName)
  local prefixedBranchName="$prefix$branchName"
  git checkout "$main_branch"
  git fetch
  git reset --hard origin/"$main_branch"
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
  if [[ -n ${ZSH_VERSION:-} ]]; then
    setopt localoptions ksharrays
  fi

  local query
  local branchPattern
  local display_names
  local branch_names
  local currBranch
  local raw_branches_str
  local current_timestamp
  local brName
  local timestamp
  local display_name
  local days_ago
  query=$1
  branchPattern="refs/heads/"$([ $# -eq 0 ] && echo '' || echo "**/*$query*")
  display_names=()
  branch_names=()
  currBranch=$(getBranchName)
  current_timestamp=$(date +%s)

  raw_branches_str=$(git for-each-ref --format='%(refname:short)|%(committerdate:unix)' "$branchPattern" --ignore-case | sort -t'|' -k2 -nr)

  while IFS='|' read -r brName timestamp; do
    [[ -z ${brName:-} ]] && continue

    if [[ $brName != "$currBranch" ]]; then
      days_ago=$(( (current_timestamp - timestamp) / 86400 ))
      display_name="$brName (-${days_ago}d)"
      display_names+=("$display_name")
      branch_names+=("$brName")
    fi
  done <<< "$raw_branches_str"

  local optsLen=${#display_names[@]}
  local selection
  case $optsLen in
  0) _echoError "No branches found" ;;
  1) git checkout "${branch_names[0]}" ;;
  *)
    for ((i = 0; i < optsLen; i++)); do
      printf '%d) %s\n' "$((i + 1))" "${display_names[$i]}"
    done

    while true; do
      printf 'Select branch number: '
      read -r selection

      if [[ $selection =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= optsLen )); then
        git checkout "${branch_names[$((selection - 1))]}"
        break
      fi

      _echoError "Enter a number between 1 and $optsLen."
    done
    ;;
  esac
}

# First param is command (push or push-force)
# Optional --force flag to force push on the repo's main branch.
_runGitCommandWithMasterProtection() {
  local commandKey=$1
  local br
  local main_branch
  br=$(getBranchName)
  main_branch=$(mainBranchName)
  if [[ $br == "$main_branch" ]] && ! _has_param "--force" "$@"; then
    _echoError "Use '--force' flag to perform this operation on $main_branch. Are you on the correct branch?"
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

brName() {
  local branchTitle=$1
  # Replace any non letter or number characters with dashes to create a branch name
  echo "$branchTitle" | awk '{print tolower($0)}' | sed -e 's/[^a-zA-Z0-9]/-/g' | pbcopy
}

glol() {
  local format='%C(bold blue)%<(10,trunc)%an%Creset %Cgreen%<(10,trunc)%cr%Creset %C(auto)%s%Creset'
  if _has_param "--hash" "$@"; then
    format="%C(yellow)%h%Creset $format"
  fi
  git -c color.ui=always log --pretty="$format" | less -R
}

alias gc-='git checkout -'
alias gm-='git merge -'
alias gcwip='git add -A;git commit -m "wip"'
alias gst='git status'
alias sup='git fetch &> /dev/null;gst'
alias gl='git pull'
# Reset hard to remote branch
alias rerem='git reset --hard origin/$(getBranchName)'
# Reset hard to previous local branch
alias relast='git reset --hard @{-1}'
alias amend='git add .;git commit --amend'
alias lastcommit='git log -1 --pretty=%B | cat'

grim() {
  git rebase -i "$(mainBranchName)"
}

gcm() {
  git checkout "$(mainBranchName)"
}

# Fetch latest default branch, then interactive rebase on it
fgrim() {
  gcm &> /dev/null
  gl &> /dev/null
  gc- &> /dev/null
  grim
}

# Switch to default branch then delete previous local branch
gdel() {
  gcm &> /dev/null
  git branch -D "@{-1}"
}

freshen() {
  git pull --rebase origin "$(mainBranchName)"
}

# Show LOC change stats for current branch compared to the repo's main branch.
loc() {
  git fetch &> /dev/null
  git diff --shortstat "origin/$(mainBranchName)"
}
