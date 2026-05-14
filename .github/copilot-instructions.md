# Repository instructions

- This repository contains personal utilities and configuration, including an in-progress shell-config rearchitecture.
- For shell-config work, **bash and zsh must both work**, but **zsh is the first-class interactive experience**.
- Preserve existing behavior unless this repository's feature plan explicitly changes it.
- Preserve **PATH ordering** unless intentionally changing it as part of the design; do not replace PATH with a machine-specific snapshot.
- Keep **shared logic**, **local/private machine-specific logic**, and **secrets loading** as separate concerns.
- Do not place raw secrets in tracked shared config. Prefer a separate non-committed secrets-loading mechanism.
- Treat files in `features/` as living feature plans. When a feature plan exists for the work, read it first and keep it updated as meaningful design decisions are made.
- Prefer repository-wide policy in this file and more detailed area-specific rules in `.github/instructions/*.instructions.md`.
- For shell-config changes, favor clear startup-file responsibilities, direct sourcing or symlinks over copy-based refresh flows, and migration-safe validation in fresh shell sessions.
