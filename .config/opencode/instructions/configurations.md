# Configurations Repo — OpenCode Instructions

This repository is a **dotfiles repo** that tracks `~/` (the home directory).
Repo lives at `/home/lucas/config_workspace/` — NOT at `~/`.

## Sync strategy: full symlink

`apply_dotfiles` in `.scripts/setup.sh` creates symlinks from `~/` into the repo
for every tracked path. **Editing a file in the repo IS editing the live file.**
No manual copy is ever needed.

| Repo path | Live symlink |
|---|---|
| `.zshrc` | `~/.zshrc` |
| `.p10k.zsh` | `~/.p10k.zsh` |
| `.fzf.zsh` | `~/.fzf.zsh` |
| `.tmux.conf` | `~/.tmux.conf` |
| `.scripts/` | `~/.scripts/` |
| `.config/nvim/` | `~/.config/nvim/` |
| `.config/alacritty/` | `~/.config/alacritty/` |
| `.config/opencode/` | `~/.config/opencode/` |

Never edit files directly under `~/` — they are symlinks back to this repo.

## tmux2k custom plugins gotcha

`.scripts/calc.sh` and `.scripts/copilot.sh` are custom tmux2k plugins referenced
in `.tmux.conf`. They cannot live permanently in `~/.tmux/plugins/tmux2k/plugins/`
because TPM manages that dir as a git repo — `tpm update` would delete them.

`link_tmux2k_plugins` in `setup.sh` creates symlinks after TPM installs tmux2k:
```
~/.tmux/plugins/tmux2k/plugins/calc.sh    → ~/.scripts/calc.sh
~/.tmux/plugins/tmux2k/plugins/copilot.sh → ~/.scripts/copilot.sh
```

## .gitignore

The root `.gitignore` explicitly lists files and patterns to exclude. It does NOT
use a `*` + whitelist pattern — all files are tracked by default unless excluded.

Currently excluded: `.engram/*.db`, `.engram/*.db-shm`, `.engram/*.db-wal`
(Engram persistent memory DB — synced via Syncthing, not git).

## Adding new files

1. Create the file inside the repo.
2. If the file should NOT be tracked (e.g. binary state, secrets), add it to `.gitignore`.
3. Re-run `bash .scripts/setup.sh` to create the symlink (for new standalone files
   or new top-level dirs). Files inside already-symlinked directories (e.g.
   `.config/nvim/`, `.scripts/`) propagate automatically — no setup re-run needed.

## Multi-PC workflow

1. Edit on machine A → commit → push.
2. On machine B: `git pull` — live files update instantly via symlinks.
3. Adding a new file: re-run `setup.sh` on each machine to create the new symlink.
4. Engram memory DB is synced separately via Syncthing — not via git.

## Project launcher system

`.scripts/projects/` — JSON project definitions (schema: `project.schema.json`).
- `launch_project.sh` / `close_project.sh` — generic entry points
- `launch_heethr.sh`, `launch_flare.sh` — project-specific wrappers

Adding a project: create `.scripts/projects/<name>.json`. Because `.scripts/` is
a symlinked directory, it appears at `~/.scripts/projects/<name>.json` automatically.

## Git rules (ABSOLUTE)

- **NEVER perform any git operation (add/commit/push/PR) without explicit user instruction — NO EXCEPTIONS.**
- Describe what would be staged/committed/pushed and wait for explicit confirmation.
