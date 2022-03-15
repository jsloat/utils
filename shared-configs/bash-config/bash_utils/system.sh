# Configure this to point to the directory containing the utils repo
UTILS_REPO_PATH="$HOME/Dev/utils"
BASH_CONFIG_REPO_DIR="$UTILS_REPO_PATH/shared-configs/bash-config"

_pullLatestBashSettings() {
  echo "Pulling latest settings from GitHub"
  local INIT_DIR=$(pwd)
  cd "$UTILS_REPO_PATH"
  git checkout master
  git pull
  cd "$INIT_DIR"
}

_makeFileIfMissing() {
  local filePath=$1
  # file | folder
  local fileType=$2
  if test ! -e $filePath; then
    case $fileType in
    file) touch $filePath ;;
    folder) mkdir $filePath ;;
    esac
  fi
}

# NB: This will overwrite files in the root directory
_overwriteBashSettings() {
  echo "Copying files"
  _makeFileIfMissing $HOME/bash_utils folder
  cp -Rf $BASH_CONFIG_REPO_DIR/bash_utils/ $HOME/bash_utils
  _makeFileIfMissing $HOME/.bashrc file
  cp -f $BASH_CONFIG_REPO_DIR/bashrc.sh $HOME/.bashrc
  _makeFileIfMissing $HOME/.bash_profile file
  cp -f $BASH_CONFIG_REPO_DIR/bash_profile.sh $HOME/.bash_profile
}

alias settings="_pullLatestBashSettings;code $UTILS_REPO_PATH"
alias reload="source $HOME/.bashrc"

# Pass "nopull" to skip pulling latest from master
updateSettings() {
  local noPull=$1
  if [[ $noPull != 'nopull' ]]; then
    _pullLatestBashSettings
  fi
  _overwriteBashSettings
  reload
  echo "Done"
}
