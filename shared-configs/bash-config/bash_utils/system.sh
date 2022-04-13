#!/bin/bash

# Configure this to point to the directory containing the utils repo
UTILS_REPO_PATH="$HOME/Dev/utils"
BASH_CONFIG_REPO_DIR="$UTILS_REPO_PATH/shared-configs/bash-config"

_pullLatestBashSettings() {
  _echoAnnouncement 'Pulling latest settings from GitHub'
  local INIT_DIR
  INIT_DIR=$(pwd)
  cd "$UTILS_REPO_PATH" || exit
  git checkout master
  git pull
  cd "$INIT_DIR" || exit
}

_makeFileIfMissing() {
  local filePath=$1
  # file | folder
  local fileType=$2
  if test ! -e "$filePath"; then
    case $fileType in
    file) touch "$filePath" ;;
    folder) mkdir "$filePath" ;;
    esac
  fi
}

# NB: This will overwrite files in the root directory
_overwriteBashSettings() {
  _echoAnnouncement 'Copying files'
  _makeFileIfMissing "$HOME"/bash_utils folder
  cp -Rf "$BASH_CONFIG_REPO_DIR"/bash_utils/ "$HOME"/bash_utils
  _makeFileIfMissing "$HOME"/.bashrc file
  cp -f "$BASH_CONFIG_REPO_DIR"/bashrc.sh "$HOME"/.bashrc
  _makeFileIfMissing "$HOME"/.bash_profile file
  cp -f "$BASH_CONFIG_REPO_DIR"/bash_profile.sh "$HOME"/.bash_profile
}

# shellcheck disable=2139
alias settings="_pullLatestBashSettings;code $UTILS_REPO_PATH"
# shellcheck disable=2139
alias reload="_echoAnnouncement 'Reloading terminal session';source $HOME/.bashrc"

# Pass "local" to skip pulling latest from master
refresh() {
  local isLocal=$1
  if [[ $isLocal != 'local' ]]; then
    _pullLatestBashSettings
  fi
  _overwriteBashSettings
  reload
  _echoAnnouncement "Done"
}
