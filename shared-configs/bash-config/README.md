# Shell config

This directory currently contains the legacy shell-config source files that are being migrated into the repo-root shell layout.

## Current workflow

### Install or repair shell symlinks

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

The installer:

- wires `~/.bash_profile` and `~/.bashrc`
- wires `~/.zprofile` and `~/.zshrc`
- backs up conflicting existing files
- is safe to re-run

### Pull latest changes and apply them

After your shell config is loaded, use:

```bash
shell_update
```

That will:

1. pull the latest repo changes with `git pull --ff-only`
2. run `bash "$HOME/Dev/utils/install.sh" --shell both`
3. reload the current shell session

### Reload local changes without pulling from git

If you edited files locally and just want the current shell session to pick them up:

```bash
shell_reload
```

### Deploy convenience command

From the repo root:

```bash
npm run deploy
```

That command pushes to git, then runs the local shell update flow.

For a no-side-effects check of the deploy path:

```bash
DEPLOY_DRY_RUN=1 npm run deploy
```

## Validation

Run the shell validation flow from the repo root:

```bash
npm run test:shell-config
```

This validates:

- ShellCheck on supported shell files
- zsh syntax with `zsh -n`
- installer dry-run behavior
- shared helper sourcing in bash and zsh
- deploy dry-run behavior without pushing or installing

### Required tool

Install ShellCheck with Homebrew:

```bash
brew install shellcheck
```

## Switching shells on macOS

### Terminal.app

1. Open `Terminal > Settings > General`
2. Under **Shells open with**, choose **Command (complete path)**
3. Enter the shell path you want, for example:
   - `/bin/zsh`
   - `/opt/homebrew/bin/bash`

### VS Code

Use **Terminal: Select Default Profile** and choose the shell you want VS Code terminals to launch.

## Current support policy

- bash and zsh must both work
- zsh is the first-class interactive experience
- shared helpers should remain shared where practical
- prompt, completion, history, and other interactive UX can be shell-specific

## Notes

- This directory is still part of an active migration. Some scripts currently source files from here until the flattening work is complete.
- Legacy command names like `refresh`, `reload`, and `reload_session` currently delegate to the newer workflows, but `shell_update` and `shell_reload` are the preferred names.
