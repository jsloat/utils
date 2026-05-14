#!/bin/bash

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)

cd "$REPO_ROOT"

# shellcheck disable=SC1091
source ./shared/textFormatting.sh
# shellcheck disable=SC1091
source ./shared/common.sh
# shellcheck disable=SC1091
source ./shared/system.sh

if [[ -n ${DEPLOY_DRY_RUN:-} ]]; then
  echo "Skipping git push (dry run)"
  shell_update --local --dry-run
else
  git push
  shell_update --local
fi
