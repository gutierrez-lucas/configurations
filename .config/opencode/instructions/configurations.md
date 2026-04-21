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

## .gitignore gotcha

Root `.gitignore` starts with `*` (ignore everything) and whitelists tracked paths
explicitly. **Any new file will be silently untracked unless you add `!/<path>`
to `.gitignore`.**

## Adding new files

1. Create the file inside the repo.
2. Add `!/<path>` to `.gitignore`.
3. Re-run `bash .scripts/setup.sh` to create the symlink (for new standalone files
   or new top-level dirs). Files inside already-symlinked directories (e.g.
   `.config/nvim/`, `.scripts/`) propagate automatically — no setup re-run needed.

## Multi-PC workflow

1. Edit on machine A → commit → push.
2. On machine B: `git pull` — live files update instantly via symlinks.
3. Adding a new file: also add `!/<path>` to `.gitignore` and re-run `setup.sh`
   on each machine to create the new symlink.

## Project launcher system

`.scripts/projects/` — JSON project definitions (schema: `project.schema.json`).
- `launch_project.sh` / `close_project.sh` — generic entry points
- `launch_heethr.sh`, `launch_flare.sh` — project-specific wrappers

Adding a project: create `.scripts/projects/<name>.json`. Because `.scripts/` is
a symlinked directory, it appears at `~/.scripts/projects/<name>.json` automatically.
