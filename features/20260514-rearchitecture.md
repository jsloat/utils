# Bash Config Rearchitecture

## Summary

Re-architect the shell configuration setup so the repo is the durable source of truth without relying on copy-based refresh flows that can drift from the live dotfiles on disk.

The new design should preserve the parts that are working well today:

- version-controlled shell configuration
- modular helper files by concern
- optional private machine-specific extensions
- fast interactive workflow for daily shell use

while addressing the main failure modes:

- copied files drifting from the repo
- machine-specific path setup being spread across multiple places
- unclear bootstrap behavior for new machines or new shell sessions
- difficulty reasoning about what is actually loaded in a live shell

## Current-state observations

### Inferred goals of the existing setup

1. Maintain one reusable bash setup in git for multiple machines.
2. Keep shared logic separate from private or machine-specific logic.
3. Make it easy to refresh a machine from the repo.
4. Provide a set of personal productivity helpers for git, system, and macOS workflows.
5. Standardize on a modern bash environment on macOS.

### Main architectural issue

The current setup treats the repo as a template that copies files into `~/.bash_profile`, `~/.bashrc`, and `~/bash_utils`.

That copy-based deployment model is the root of configuration drift. A repo file can be correct while the live dotfile is stale, overwritten, or partially updated. The recent `tdk` issue is an example of this class of problem.

## Confirmed constraints / preferences

- keep using a single `private.sh` concept for machine-specific functionality rather than introducing separate `work.sh` and `personal.sh`
- create a dedicated `path.sh` that lives in git, but keep it generic and machine-safe rather than hard-coding one machine's full PATH
- leave the existing riskier git helpers alone for this migration
- include symlink/setup instructions in the top-level README as part of the eventual implementation
- plan only for now; do not change repo files beyond this feature plan and the `features/README.md`

## Proposed target architecture

### High-level shape

Move to a structure where the live dotfiles are tiny stable entrypoints and the repo files are sourced directly.

Example target shape:

```text
~/.bash_profile                 # tiny login-shell entrypoint
~/.bashrc                       # tiny interactive-shell entrypoint

~/Dev/utils/shared-configs/bash-config/
  README.md
  bash/
    profile.sh
    rc.sh
  shared/
    env.sh
    path.sh
    prompt.sh
    aliases.sh
    functions/
      git.sh
      macos.sh
      shell.sh
  local/
    private.example.sh
```

This does not require the exact directory names above, but the architecture should follow these principles:

1. **Tiny dotfiles**: `~/.bash_profile` and `~/.bashrc` should do little more than source repo-managed files.
2. **Direct sourcing or symlinks, not copying**: a machine should either symlink the files once or source the repo paths directly.
3. **Clear separation of concerns**:
   - login shell setup
   - interactive shell setup
   - PATH management
   - aliases / prompt / reusable functions
   - optional private machine-specific additions
4. **Idempotent bootstrap**: setup should be safe to run repeatedly.
5. **Easy debugging**: it should be obvious which files are loaded and in what order.

### Dotfile strategy

Preferred direction:

- `~/.bash_profile` sources the repo login entrypoint and then loads `~/.bashrc` if appropriate
- `~/.bashrc` sources the repo interactive entrypoint
- the repo-managed files contain the real logic

This can be implemented either with:

1. **small sourced dotfiles**
2. **symlinked dotfiles**

Either is acceptable. The key requirement is that the repo remain the live source of truth instead of copying its contents elsewhere.

### Bootstrap / install strategy

Add an install script that creates or repairs the symlinked entrypoints for the supported shells.

Expected responsibilities of the install script:

- create the target dotfiles or symlinks for bash and zsh
- avoid destructive overwrites without an explicit flag
- back up or warn on conflicting existing files
- be safe to re-run
- print what it configured and what the next manual step is

Initial target behavior:

- bash: wire `~/.bash_profile` and `~/.bashrc`
- zsh: wire `~/.zprofile` and `~/.zshrc`
- optional: support a `--shell bash|zsh|both` mode

This install script should replace the current copy-based `refresh` concept as the main bootstrap mechanism.

## PATH strategy

Create a dedicated `path.sh` in git.

Important design rule: `path.sh` should contain **logic**, not machine-specific snapshots of PATH values.

Good contents for `path.sh`:

- helper like `add_to_path "/some/dir"`
- conditional additions only when directories exist
- de-duplication so repeated sourcing does not grow PATH
- ordered insertion for important tool directories

Bad contents for `path.sh`:

- a pasted full PATH string from one machine
- environment values that only make sense on one laptop unless guarded

Example design intent:

```bash
add_to_path "$HOME/.truveta/bin"
add_to_path "$HOME/.local/bin"
add_to_path "/opt/homebrew/bin"
```

with each entry added only if present and only once.

## Private / machine-specific strategy

Keep `private.sh` as the single machine-specific escape hatch.

Expected role of `private.sh` in the new design:

- non-shared aliases or helpers
- machine-only tool locations
- secrets references or local environment variables
- any work/personal distinctions that are actually machine-local

Important guardrail:

- `private.sh` should be optional and ignored by git
- the shared startup path should behave correctly when it is absent

Recommended directory intent:

- `shared/` contains tracked portable logic
- `local/` contains machine-local hooks and examples
- the actual private layer should live in that local area, e.g. `local/private.sh`

Consider also adding a tracked `local/private.example.sh` to document the expected contract.

## `system.sh` analysis and simplification suggestions

The current `system.sh` is doing deployment/bootstrap work rather than normal shell runtime behavior.

### Current responsibilities

- hard-code the utils repo location
- git checkout/pull the repo
- copy config files into home directory
- create missing files and directories
- reload the shell
- provide aliases around those operations

### Problems with the current design

1. **Hard-coded repo path**
   - `UTILS_REPO_PATH="$HOME/Dev/utils"` assumes one repo location
   - this makes the setup less portable and harder to reason about

2. **Shell config mutates itself via git operations**
   - `git checkout master` and `git pull` from within a shell helper mixes shell startup concerns with repo update workflow
   - it also bakes branch assumptions into the config

3. **Copy-based refresh**
   - `_overwriteBashSettings` is the main source of drift
   - it obscures whether the live dotfiles match the repo

4. **Multiple commands whose purpose overlaps**
   - `settings`, `reload`, `reload_session`, and `refresh` are conceptually close but not cleanly separated

5. **Bootstrap logic is coupled to runtime**
   - one-time machine setup and everyday shell helpers should not live in the same mental bucket

### Recommendation for `system.sh`

Replace most of the current file with a much smaller set of explicit responsibilities.

#### Remove entirely

- `_pullLatestBashSettings`
- `_makeFileIfMissing`
- `_overwriteBashSettings`
- `refresh` in its current copy-based form

These should be replaced by either:

- a one-time symlink/bootstrap script, or
- documented manual setup steps

#### Replace with simpler commands

- `settings` -> replace with something like `shell-config` that only opens the config repo
- `reload` / `reload_session` -> replace with one clear `shell-reload` command
- `refresh` -> if retained, redefine it as "repair/recreate symlinks and print status", not "copy files and pull git"

#### New responsibilities worth keeping

- a small `shell-doctor` command that reports:
  - current shell
  - loaded entrypoints
  - whether optional private file exists
  - whether expected PATH directories are present
  - whether symlinks are configured correctly

### Net result

`system.sh` should shrink dramatically. In the new world it should help inspect and reload the shell, not deploy and overwrite it.

## Zsh / alternate shell considerations

Switching to zsh does not invalidate most of this work.

The main architectural improvements are shell-agnostic:

- avoid copy-based deployment
- centralize PATH logic
- keep tiny entrypoint dotfiles
- isolate private machine-specific behavior
- document bootstrap and debugging clearly

What would change if zsh becomes the target shell:

1. shell-specific entrypoints would differ (`.zprofile`, `.zshrc` instead of bash files)
2. some helper functions may need compatibility cleanup
3. prompt configuration may be implemented differently
4. bash-only assumptions should be isolated so shared logic remains portable

Recommended approach:

- design the shared structure to be as POSIX-friendly as practical
- keep shell-specific wrappers thin
- explicitly choose one of these paths before implementation:
  1. **stay on bash**
  2. **support both bash and zsh**
  3. **migrate to zsh and keep bash compatibility only where cheap**

Current preference from discussion: aim to **support both bash and zsh** so migration to zsh can be gradual and low-risk.

### Why zsh is attractive here

On a locked-down macOS work machine, zsh is a strong candidate because it is already installed and commonly supported.

Benefits for this use case:

- better interactive completion experience than plain bash defaults
- better history/search UX once configured
- no dependence on extra third-party shell installations
- easy to adopt incrementally if the shared logic is separated from shell-specific wiring

### What zsh changes relative to the current repo

If zsh sourced the current tracked files directly, most helper functions would load, but some parts are bash-specific or need adaptation.

Confirmed tracked-file compatibility findings:

- **prompt definition is bash-specific**: the current `PS1` uses bash prompt escapes like `\[` and `\]`, so it will not render correctly in zsh
- **`del()` prompt is bash-specific**: it uses `read -p`, which errors in zsh (`zsh:read: -p: no coprocess`)
- **`common.sh` needs a small compatibility cleanup**: `export -f _has_param` is bash-oriented and should be removed or guarded in the shared implementation
- **bash-only environment conventions** like `BASH_SILENCE_DEPRECATION_WARNING` are irrelevant outside bash

Things that appear portable or close to portable:

- most aliases
- most git helper functions
- most simple shell functions using `[[ ... ]]`, `local`, loops, and command substitution

Implication for implementation:

- shared helpers can probably remain largely shared
- prompt, completion, history behavior, and a small number of interactive functions should be isolated into shell-specific files
- explicitly fix the `common.sh` `_has_param` export behavior during the migration so shared helpers stay zsh-safe

### Secrets and the local/private layer

The local/private layer is necessary, but secrets should not live in the main private helper file long-term.

Target direction:

- keep machine-local functions and aliases in `local/private.sh`
- move secrets and credential exports to a separate non-committed secrets file or another local credential-loading mechanism
- have `local/private.sh` source that secrets file only if it exists

### Switching between bash and zsh on macOS

The implementation docs should explain both shell-selection concepts:

1. **Terminal app startup shell**
   - In Terminal: `Terminal > Settings > General`
   - Under **Shells open with**, choose **Command (complete path)**
   - Enter the shell path, e.g. `/bin/zsh` or `/opt/homebrew/bin/bash`

2. **User login shell**
   - optionally change with `chsh` if desired and permitted in the environment
   - this is separate from Terminal's per-app startup configuration

The docs should clarify that switching Terminal to zsh does not require rewriting all scripts; it mainly changes the interactive shell and startup files that are read.

### `compinit`

`compinit` is zsh's completion system initializer.

Typical usage:

```zsh
autoload -Uz compinit
compinit
```

It enables zsh's richer completion framework, loads completion functions from `fpath`, and wires the completion widgets used by interactive keybindings like Tab completion.

For this feature, zsh completion setup should be a first-class part of the zsh-specific runtime entrypoint.

## Testing / validation methodology

Yes, some testing is worth doing for this migration.

The goal is not exhaustive unit testing. The goal is migration safety: verify that the new setup still exposes the expected commands and environment in fresh shell sessions.

### Why tests are valuable here

This migration changes shell initialization and file-loading behavior. Those are exactly the kinds of changes that can appear to work in one open terminal while failing in a new session.

### Recommended testing level

Add lightweight smoke tests rather than a heavy test suite.

Candidate checks:

1. start a fresh shell and confirm startup produces no errors
2. confirm expected core functions and aliases exist
3. confirm optional `private.sh` absence does not break startup
4. confirm `path.sh` adds key directories exactly once
5. confirm `tdk`-style tools remain available in new terminal sessions when their directories exist
6. confirm bootstrap/symlink setup is idempotent
7. if zsh support is introduced, run the same smoke checks there
8. verify the install script creates expected symlinks and remains idempotent for bash, zsh, and dual-shell modes

### Suggested implementation options

- a small shell-based smoke test script
- or Bats, if the extra dependency feels worthwhile

Initial recommendation:

- start with simple shell smoke tests
- only adopt a heavier test framework if the tests begin to grow materially

## Documentation updates to include during implementation

1. update the top-level README with:
   - purpose of the shell config repo
   - install-script and symlink instructions
   - expected file-loading model
   - private-file conventions
   - reload/debugging instructions
   - how to switch Terminal to bash or zsh on macOS
2. update the bash-config README to reflect the new architecture
3. document the role of `path.sh`
4. document bash/zsh support and migration guidance
5. document what `compinit` is doing in the zsh setup

## AI instruction files strategy

Use repository instruction files to codify the long-lived strategy for this repo.

Recommended structure:

1. **Repository-wide instructions**
   - create `.github/copilot-instructions.md`
   - use it for high-level rules and stable expectations across the repo
   - include things like:
     - bash and zsh must both work
     - zsh is the first-class interactive experience
     - preserve PATH ordering unless intentionally changed
     - shared vs local/private vs secrets responsibilities
     - preferred validation approach for shell config changes

2. **Path-specific instructions**
   - create one or more files under `.github/instructions/*.instructions.md`
   - use `applyTo` frontmatter to target the shell config area specifically
   - likely target paths under `shared-configs/bash-config/**`
   - use these for more detailed shell-config rules that would be too noisy for the repo-wide instructions

3. **Agent-oriented notes**
   - consider whether an `AGENTS.md` file near the shell config area would be helpful for agent workflows
   - only add this if it adds something meaningfully different from the repository-wide and path-specific instruction files

Recommended split of concerns:

- `.github/copilot-instructions.md` -> repo-wide philosophy and support policy
- `.github/instructions/shell-config.instructions.md` -> shell-specific architecture and editing rules
- feature plans in `features/` -> time-bounded project plans and evolving migration context

This should help keep strategy durable without overloading the feature plan with permanent policy.

Implementation priority:

- create the instruction files first, before the larger shell rearchitecture work
- treat them as living guidance and update them as the implementation evolves
- revise them whenever we make a meaningful architectural decision that future AI sessions should inherit

Additional instruction files to consider if they prove useful:

- `.github/instructions/feature-plans.instructions.md` for `features/**/*.md`
  - guidance on plan structure, checklist style, and how feature plans should be updated over time
- `.github/instructions/docs.instructions.md` for README and docs updates
  - guidance on setup docs, migration notes, and shell-support documentation expectations
- `shared-configs/bash-config/AGENTS.md`
  - only if agent-specific workflow notes are needed beyond what the other instruction files already cover

## Other-machine migration notes

This feature should include explicit guidance for migrating the setup on the other machine.

Minimum deliverable:

- a documented step-by-step migration section in the feature plan and/or README

Nice-to-have:

- a copy-paste prompt or checklist that can be used in a future AI session to perform the migration safely on the second machine

Key migration concerns to document:

- preserve existing PATH ordering
- back up any pre-existing dotfiles before wiring symlinks
- verify which shell Terminal and VS Code are configured to launch
- handle the presence or absence of the local/private and secrets files
- validate tool availability in a fresh session after setup

## Migration phases

### Phase 1: design and scaffolding

- create repo-wide and path-specific instruction files first
- choose the final target shell strategy: bash-only, dual-shell, or zsh-first
- choose sourcing vs symlink preference
- define final file layout
- define `path.sh` behavior and helper contract
- define the `private.sh` contract

### Phase 2: bootstrap architecture

- create tiny stable entrypoint dotfiles
- create repo-managed runtime entrypoints
- add install script that creates or repairs bash/zsh symlinks
- replace copy-based refresh with direct sourcing or symlinks
- add a minimal shell doctor / reload workflow

### Phase 3: module cleanup

- split or rename files by clear responsibility
- simplify `system.sh`
- move PATH logic into `path.sh`
- keep existing git helpers unchanged unless required by the migration

### Phase 4: documentation and smoke tests

- write top-level README setup instructions
- update bash-config README
- define repo-wide and path-specific AI instruction files
- add migration-safe smoke tests
- test fresh shell startup behavior

### Phase 5: dual-shell support and optional migration

- add zsh wrappers while preserving bash support
- document how to switch Terminal to zsh and back
- add zsh completion/history initialization via `compinit`
- document the migration procedure for the other machine
- validate the same smoke-test contract under zsh

## Risks / open questions

1. Should the install script default to wiring both bash and zsh, or require an explicit shell choice?
2. Should the machine bootstrap be symlink-based, source-based, or support both?
3. How much of the current helper surface is still actively used versus historical residue?
4. Should there be a dedicated `shell-doctor` command from the start, or can documentation carry the load initially?
5. Do we want minimal smoke tests only, or a small formal test harness?
6. Do we want to add both `.github/copilot-instructions.md` and a shell-specific `.github/instructions/*.instructions.md` file in the same implementation pass?
7. Which additional instruction files are worth adding immediately versus only after real duplication appears?

## Implementation checklist

- [ ] choose target shell strategy
- [ ] create `.github/copilot-instructions.md`
- [ ] create `.github/instructions/shell-config.instructions.md`
- [ ] decide whether to add additional instruction files now or later
- [ ] update instruction files as the implementation evolves
- [ ] decide install-script behavior for bash, zsh, or both
- [ ] choose source-vs-symlink bootstrap model
- [ ] design final directory layout
- [ ] define `path.sh` helper contract
- [ ] define `private.sh` contract and example file
- [ ] design `local/private.sh` loading behavior
- [ ] replace copy-based deployment model
- [ ] add install script for symlink/bootstrap setup
- [ ] simplify `system.sh` to reload/inspect responsibilities
- [ ] add top-level README setup instructions including symlinking
- [ ] update bash-config README
- [ ] add repo-wide and path-specific AI instruction files
- [ ] add smoke tests for fresh shell startup
- [ ] validate PATH and tool availability in fresh sessions
- [ ] add bash + zsh support and migration guidance
- [ ] document and rehearse migration steps for the other machine

## Recommendation

Proceed with the rearchitecture even if zsh remains undecided.

The highest-value changes are independent of shell choice:

- eliminate copy-based drift
- centralize PATH logic
- clarify private vs shared responsibilities
- document bootstrap clearly
- add migration-safe smoke tests

Those improvements will pay off whether the end state is modern bash, zsh, or dual support.
