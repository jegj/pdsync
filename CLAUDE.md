# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`pdsync` is a single-file Bash script that creates encrypted, compressed backups of specified folders, optionally uploads them to AWS S3, and handles large file splitting for vFAT filesystems.

## Linting

```sh
shellcheck pdsync.sh install.sh
```

CI runs `shellcheck` on every push to `main` via `.github/workflows/check.yml`.

## Architecture

Two files matter:

- **`pdsync.sh`** — the entire backup logic in one Bash script
- **`install.sh`** — copies `pdsync.sh` to `$HOME/.local/bin/pdsync`

### Script flow (`pdsync.sh`)

1. `parse_params()` — parses CLI args, stores folders into `arrVar[]`
2. `check_dependecies()` — verifies `aws` and `gpg` are on PATH
3. `check_input()` — validates required GPG flags (`-e`, `-r`)
4. Pipes `tar` → `gpg` in a single command to create an encrypted `.tar.xz.asc` in the transition or destination folder
5. Sends a `notify-send` desktop notification with result
6. Optionally prunes old backups via `find -mtime`
7. Optionally uploads `.asc` file to S3 (day-of-week gating or `--force_upload`)
8. If `--transition_folder` is set and file exceeds 4 GB, splits into 6 chunks (`split -n 6`) and moves them to destination

### Key details

- All stdout/stderr are redirected to `/tmp/<backup_name>.out` and `/tmp/<backup_name>.err`
- `tar` excludes `.git` and `node_modules`
- GPG uses `--pinentry-mode=loopback --batch` for non-interactive use
- File splitting uses exactly 6 chunks (indices `00`–`05`) hardcoded in the loop
- `XDG_RUNTIME_DIR` must be set for `notify-send` to work in cron jobs
