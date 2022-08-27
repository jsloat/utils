## Dependencies

- [VS Code CLI util](https://code.visualstudio.com/docs/setup/mac)
- Updated bash
  - Mac ships with a very old version, need to update it.
  - [Installing updated bash on Mac](https://itnext.io/upgrading-bash-on-macos-7138bd1066ba)

## First-time installation

After getting everything setup, you can just run `refresh` to load the latest version of these config files to your machine.

For the initial set up, run the following code in the terminal (with the correct path to this git repo, locally):

```
source $PATH_TO_REPO/shared-configs/bash-config/bash_utils/textFormatting.sh
source $PATH_TO_REPO/shared-configs/bash-config/bash_utils/system.sh
refresh local
```

## Setting default terminal to bash

### Mac terminal

Terminal settings > General > Shell opens with > Command > /bin/bash

### VS Code

Command pallette > Terminal: Select default profile
