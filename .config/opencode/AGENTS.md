# OpenCode Global Instructions Index
**Last updated:** March 2026 (v2.2)

This file is the OpenCode global rules entry point. It is loaded in every session.

Project-specific knowledge bases are split into separate files under
`~/.config/opencode/instructions/` and loaded **per-directory** via an `opencode.json`
placed in each project's root directory.

## Always-loaded (global)

| File | Contents |
|------|----------|
| `instructions/global-rules.md` | Git & GitHub rules — apply to ALL repos unconditionally |

## Per-project (loaded only when opening that directory)

| Project dir | `opencode.json` loads |
|-------------|----------------------|
| `/home/lucas/Work/Heether/` | `instructions/heethr.md` — Heethr snow melting platform (backend + dashboard) |
| `/home/lucas/Work/FlareSense/` | `instructions/flaresense.md` — FlareSense ESP32 firmware |

## Adding a new project

1. Create `~/.config/opencode/instructions/<project>.md` with the full code reference.
2. Create an `opencode.json` in the project root:
   ```json
   {
     "$schema": "https://opencode.ai/config.json",
     "instructions": ["~/.config/opencode/instructions/<project>.md"]
   }
   ```
3. Add a row to the per-project table above.
