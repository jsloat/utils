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
  zprofile
  zshrc
shared/
  *.sh
local/
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
- `~/.zprofile`
- `~/.zshrc`

It backs up conflicting files and is safe to re-run.

### Shared vs local shell files

- `bash/` and `zsh/` contain the symlink targets for interactive/login startup
- `shared/` contains tracked shell helpers loaded by both shells where practical, including `shared/path.sh` for tracked PATH rules
- `local/path.sh` is the optional machine-local PATH layer
- `local/private.sh` is the optional machine-local hook
- `local/secrets.sh` is the optional untracked secrets layer

To bootstrap the local files:

```bash
cp ./local/private.example.sh ./local/private.sh
cp ./local/path.example.sh ./local/path.sh
cp ./local/secrets.example.sh ./local/secrets.sh
```

`bash/bashrc` and `zsh/zshrc` still fall back to `~/bash_utils/private.sh` if it already exists, so older machines can migrate gradually.

### Daily workflows

After your shell config is loaded:

```bash
shell_update
```

This:

1. pulls the latest repo changes with `git pull --ff-only`
2. reruns `bash "$HOME/Dev/utils/install.sh" --shell both`
3. reloads the current shell session

If you only want to pick up **local edits**:

```bash
shell_reload
```

### Deploy helper

From the repo root:

```bash
npm run deploy
```

That command pushes to git, then runs the local shell update flow.

For a no-side-effects check:

```bash
DEPLOY_DRY_RUN=1 npm run deploy
```

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
