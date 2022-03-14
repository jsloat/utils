# Configure this to point to the directory containing the utils repo
UTILS_REPO_PATH='~/Dev/utils'
BASH_CONFIG_DIR="$UTILS_REPO_PATH/shared-configs/bash-config"

_pullLatestBashSettings() {
  local INIT_DIR=$(pwd)
  cd $UTILS_REPO_PATH
  git checkout master
  git pull
  cd $INIT_DIR
}

# NB: This will overwrite files in the root directory
_overwriteBashSettings() {
  if test ! -f '~/bash_utils'; then
    mkdir ~/bash_utils
  fi
  cp -R ./bash_utils/ ~/bash_utils
  cp ./bashrc.sh ~/.bashrc
  cp ./bash_profile.sh ~/.bash_profile
}

alias settings="code $BASH_CONFIG_DIR"
alias reload='source ~/.bashrc'

updateSettings() {
  _pullLatestBashSettings
  _overwriteBashSettings
  reload
  echo "Reloaded with pulled settings"
}
