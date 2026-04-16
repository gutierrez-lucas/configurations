# Configurations Repo — OpenCode Instructions

This repository is a **dotfiles repo** that tracks `~/` (the home directory).

## Structure

All files in this repo mirror their live location under `~`.
For example:
- `.scripts/projects.sh` in this repo lives at `~/.scripts/projects.sh`
- `.config/alacritty/alacritty.toml` in this repo lives at `~/.config/alacritty/alacritty.toml`

## Propagation Rule

**Any change made in this repo must also be applied to the live `~/` location.**

This means:
1. Edit the file in the repo (e.g. `.scripts/projects.sh`).
2. Copy it to the corresponding live path (e.g. `~/.scripts/projects.sh`).
3. If the change creates a new file, ensure it also lands at the correct `~/` path.
4. If the change creates a new directory (e.g. `.scripts/projects/`), create it under `~/` too.

Never leave a change only in the repo without propagating it to `~/`, and never edit `~/` files directly without also updating the repo.

## Subdirectory propagation map

| Repo path | Live path |
|---|---|
| `.scripts/` | `~/.scripts/` |
| `.config/` | `~/.config/` |
| `.tmux/` | `~/.tmux/` |
| `.config/opencode/` | `~/.config/opencode/` |
| `.p10k.zsh` | `~/.p10k.zsh` |
| `.tmux.conf` | `~/.tmux.conf` |
| `.zshrc` | `~/.zshrc` |
| `.fzf.zsh` | `~/.fzf.zsh` |

## Scripts directory note

`.scripts/projects/` contains JSON project definitions and a JSON Schema.
The generic launcher and closer (`launch_project.sh`, `close_project.sh`) live directly in `.scripts/`.
When adding a new project, create its `.json` in `.scripts/projects/` **and** copy it to `~/.scripts/projects/`.
