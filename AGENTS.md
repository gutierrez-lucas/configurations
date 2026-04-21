# AGENTS.md — config_workspace (dotfiles repo)

## What this repo is

Dotfiles repo. Every tracked file mirrors its live location under `~`.
- `.scripts/projects.sh` in repo → `~/.scripts/projects.sh` on disk
- `.config/nvim/` in repo → `~/.config/nvim/` on disk

The repo lives at `/home/lucas/config_workspace/` (NOT at `~/`).

## Sync strategy: full symlink

`apply_dotfiles` in `.scripts/setup.sh` creates symlinks from `~/` → repo for
**everything** — both standalone files and directories. Editing a file in the
repo IS editing the live file. No manual copy is ever needed.

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

**Never edit files under `~/` directly** — they are symlinks. Always edit in the repo.

## tmux2k custom plugins gotcha

`.scripts/calc.sh` and `.scripts/copilot.sh` are custom tmux2k plugins referenced
in `.tmux.conf` as `calc` and `copilot`. They cannot live permanently inside
`~/.tmux/plugins/tmux2k/plugins/` because TPM manages that directory as a git
repo — a `tpm update` would delete any manually added files.

**Solution:** the `.scripts/` dir is their canonical home. `link_tmux2k_plugins`
in `setup.sh` creates symlinks from the tmux2k plugins dir back into `.scripts/`:

```
~/.tmux/plugins/tmux2k/plugins/calc.sh    → ~/.scripts/calc.sh    (→ repo)
~/.tmux/plugins/tmux2k/plugins/copilot.sh → ~/.scripts/copilot.sh (→ repo)
```

Since git ignores unknown files, the symlinks survive `tpm update`.

## .gitignore gotcha

The root `.gitignore` starts with `*` (ignore everything) and whitelists tracked
paths explicitly. **Any new file you create will be silently untracked unless you
add a `!/<path>` entry to `.gitignore`.**

## Bootstrap (new Ubuntu device)

```bash
git clone <repo> ~/config_workspace
cd ~/config_workspace
bash .scripts/setup.sh   # idempotent; Ubuntu only
```

Installs: zsh + oh-my-zsh + p10k, tmux + TPM, Neovim (AppImage → `/opt/nvim`),
JetBrainsMono Nerd Font, Homebrew (eza/zoxide), Rust, gh CLI, colorscript,
then calls `apply_dotfiles` (symlinks everything) and `link_tmux2k_plugins`.

After running: `exec zsh`, open `nvim` (lazy.nvim auto-bootstraps), press
`<prefix>+I` in tmux to install plugins, run `gh auth login`.

## Multi-PC workflow

Changes flow via git:
1. Edit in repo on machine A → commit → push.
2. On machine B: `git pull` — symlinks already point into the repo, so the
   live files update instantly. No re-running setup needed.
3. If adding a new tracked file: add `!/<path>` to `.gitignore`, commit, pull on
   other machines, and re-run `bash .scripts/setup.sh` to create the new symlink.

## Project launcher system

`.scripts/projects/` — JSON definitions for each project (schema at
`project.schema.json`). Generic entry points:
- `launch_project.sh` / `close_project.sh` — reads the JSON, opens tmux sessions
- Project-specific wrappers: `launch_heethr.sh`, `launch_flare.sh`, etc.

When adding a project: create `.scripts/projects/<name>.json`. Because `.scripts/`
is a symlinked directory, it propagates to `~/.scripts/projects/<name>.json`
automatically.

## OpenCode config lives here

`.config/opencode/` is symlinked to `~/.config/opencode/`. It contains:
- `AGENTS.md` — global OpenCode persona, rules, Engram protocol (loaded every session)
- `opencode.json` — agent definitions, MCP servers (Context7, Engram), permissions
- `instructions/` — per-project instruction files loaded via per-repo `opencode.json`

The `opencode.json` in this repo root loads `configurations.md` as the instruction
file for sessions opened in this directory.

## Git rules

- Never `git add`, `git commit`, or `git push` without explicit user instruction.
- Never create PRs autonomously.
- Describe what would be staged and wait for the user to confirm.
