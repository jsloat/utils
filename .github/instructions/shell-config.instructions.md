---
applyTo: "install.sh,bash/**,zsh/**,shared/**,local/**"
---

# Shell config instructions

- This area uses a direct-sourcing or symlink-based model. Do not reintroduce copy-based bootstrap or refresh flows.
- **bash and zsh must both work**, but **zsh is the first-class interactive experience**.
- Keep shared logic shell-agnostic where practical. Prompt, completion, history, and keybinding UX may be shell-specific.
- Preserve existing behavior unless the feature plan intentionally changes it.
- Preserve **PATH ordering** unless intentionally changing it as part of the design. Do not replace PATH with a machine-specific snapshot.
- Keep concerns separated:
  - shared tracked shell logic
  - local/private machine-specific logic
  - secrets loading
- Do not add raw secrets to tracked files in this area.
- Prefer tiny shell entrypoints, clear startup-file responsibilities, and direct sourcing or symlinks over copy-based bootstrap flows.
- When editing shared helpers, keep them safe for both shells. Avoid bash-only patterns in shared files unless guarded. In particular, remove or guard bash-oriented function export behavior such as `export -f`.
- Validate shell-config changes in fresh shell sessions, not only in the currently open shell.
- Read the active feature plan in `features/` before making substantial architectural changes here, and update these instructions when durable shell-architecture decisions change.
