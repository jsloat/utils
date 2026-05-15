# Utils

This repository contains personal utilities and a repo-driven shell configuration setup.

The shell setup uses a symlinked, repo-driven model with:

- **bash and zsh both supported**
- **zsh as the first-class interactive experience**
- shared tracked logic separated from local/private and secrets-only configuration

Current shell layout:

```text
bash/
  bash_profile
  bashrc
zsh/
  plugins.txt
  zprofile
  zshrc
shared/
  halp.txt
  *.sh
local/
  halp.example.txt
  path.example.sh
  private.example.sh
  secrets.example.sh
```

## Shell setup

### Install or repair symlinks

From the repo root:

```bash
bash ./install.sh --shell both
```

Useful variants:

```bash
bash ./install.sh --shell bash
bash ./install.sh --shell zsh
bash ./install.sh --shell both --dry-run
```

The installer currently manages:

- `~/.bash_profile`
- `~/.bashrc`
- `~/.hushlogin`
- `~/.zprofile`
- `~/.zshrc`

It backs up conflicting files and is safe to re-run.
It also creates `~/.hushlogin` so new login shells do not print the macOS `Last login: ...` banner.

For zsh, it also bootstraps the **antidote** plugin manager into `~/.antidote` if needed.
If `fzf` is missing, the installer warns because `fzf-tab` is configured in `zsh/plugins.txt` and its richer completion UI depends on `fzf`.
If the recommended Nerd Font is missing, the installer warns and points you to the MesloLGS NF install command plus the Terminal.app font setting.

### Shared vs local shell files

- `bash/` and `zsh/` contain the symlink targets for interactive/login startup
- `zsh/plugins.txt` declares the repo-owned zsh plugin list for antidote
- `shared/halp.txt` is the repo-owned command list for `halp`
- `shared/` contains tracked shell helpers loaded by both shells where practical, including `shared/path.sh` for tracked PATH rules and `shared/lazy.sh` for reusable lazy-loader patterns
- `local/halp.txt` is the optional machine-local extension file for `halp`
- `local/path.sh` is the optional machine-local PATH layer
- `local/private.sh` is the optional machine-local hook
- `local/secrets.sh` is the optional untracked secrets layer

To bootstrap the local files:

```bash
cp ./local/private.example.sh ./local/private.sh
cp ./local/path.example.sh ./local/path.sh
cp ./local/halp.example.txt ./local/halp.txt
cp ./local/secrets.example.sh ./local/secrets.sh
```

`bash/bashrc` and `zsh/zshrc` still fall back to `~/bash_utils/private.sh` if it already exists, so older machines can migrate gradually.

### Daily workflows

After your shell config is loaded:

```bash
shell_update
shell_install_font
```

This:

1. pulls the latest repo changes with `git pull --ff-only`
2. reloads the current shell session

If you only want to pick up **local edits**:

```bash
shell_reload
```

For the repo-owned zsh plugin layer:

```bash
zsh_plugins_edit
zsh_plugins_update
```

- `zsh_plugins_edit` opens `zsh/plugins.txt`
- `zsh_plugins_update` runs `antidote update` and reloads zsh when run from zsh
- if `fzf-tab` is enabled, install `fzf` with `brew install fzf` so tab completion gets the full interactive UI instead of degraded fallback behavior
- some plugins also need repo-owned post-load config in `zsh/zshrc`; for example, `zsh-history-substring-search` only starts handling arrow keys after its widgets are bound there

For shell-management help:

```bash
halp
```

- `halp` prints one command per line from `shared/halp.txt`
- optional machine-local additions can live in `local/halp.txt`

### Prompt font

The zsh prompt uses powerline-style glyphs, so it looks best with **MesloLGS NF**.

Install it with:

```bash
shell_install_font
```

Then select it in **Terminal.app > Settings > Profiles > Text > Font**.

## Validation

Install ShellCheck:

```bash
brew install shellcheck
```

Run shell validation from the repo root:

```bash
npm run test:shell-config
```

That covers:

- ShellCheck on supported shell files
- `zsh -n` on zsh entrypoints
- installer dry-run behavior
- shared helper sourcing in bash and zsh
- deploy dry-run behavior without pushing or installing

## Switching shells on macOS

### Terminal.app

1. Open `Terminal > Settings > General`
2. Under **Shells open with**, choose **Command (complete path)**
3. Enter the shell path you want, for example:
   - `/bin/zsh`
   - `/opt/homebrew/bin/bash`

### VS Code

Use **Terminal: Select Default Profile** and choose the shell you want VS Code terminals to launch.

## Notes

- `shell_update` uses the repo path exported by the repo-managed shell entrypoints, so the update flow follows the actual checkout location instead of assuming one hard-coded path.
- The shell smoke tests cover the shared helpers plus fresh bash/zsh startup from the symlinked entrypoints.
- The current zsh plugin layer is repo-owned config with antidote-managed installs. Plugin code itself is not vendored into this repo.
- The zsh prompt uses a powerline-style path/branch segment, so the arrow separator looks best in a Nerd Font or other Powerline-compatible font.
