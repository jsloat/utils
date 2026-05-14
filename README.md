# Utils

This repository contains personal utilities and an in-progress shell configuration rearchitecture.

The shell setup is moving from a copy-based refresh model to a symlinked, repo-driven model with:

- **bash and zsh both supported**
- **zsh as the first-class interactive experience**
- shared tracked logic separated from local/private and secrets-only configuration

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

## More detail

See `shared-configs/bash-config/README.md` for the current shell-config-specific workflow and migration notes.
