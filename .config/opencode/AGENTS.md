# OpenCode Global Instructions Index
**Last updated:** April 2026 (v2.3)

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
| `/home/lucas/Work/Heethr/` | `~/Work/Heethr/opencode/instructions/heethr.md` + `heethr-root.md` — cross-component investigation |
| `/home/lucas/Work/Heethr/snow-melting_backend/` | `~/Work/Heethr/opencode/instructions/heethr.md` + `heethr-backend.md` |
| `/home/lucas/Work/Heethr/snow-melting_dashboard/` | `~/Work/Heethr/opencode/instructions/heethr.md` + `heethr-frontend.md` |
| `/home/lucas/Work/Heethr/snow-melting_dashboard_shop/` | `~/Work/Heethr/opencode/instructions/heethr.md` + `heethr-frontend.md` |
| `/home/lucas/Work/Heethr/snow-melting_mobile/` | `~/Work/Heethr/opencode/instructions/heethr.md` + `heethr-mobile.md` |
| `/home/lucas/Work/FlareSense/` | `instructions/flaresense.md` — FlareSense ESP32 firmware |

Heethr instruction files live in the project repo at `~/Work/Heethr/opencode/instructions/`.
Per-repo `opencode.json` configs live at `~/Work/Heethr/opencode/repos/` and are symlinked
into each sub-repo by running `~/Work/Heethr/scripts/config-opencode.sh`.

## Adding a new project

**For a new standalone project (e.g. FlareSense):**
1. Create `~/.config/opencode/instructions/<project>.md` with the full code reference.
2. Create an `opencode.json` in the project root:
   ```json
   {
     "$schema": "https://opencode.ai/config.json",
     "instructions": ["~/.config/opencode/instructions/<project>.md"]
   }
   ```
3. Add a row to the per-project table above.

**For a new Heethr sub-repo:**
1. Create `~/Work/Heethr/opencode/instructions/heethr-<repo>.md`.
2. Create `~/Work/Heethr/opencode/repos/<repo>.opencode.json` referencing it.
3. Add a `link` entry to `~/Work/Heethr/scripts/config-opencode.sh`.
4. Add `opencode.json` to the sub-repo's `.gitignore`.
5. Run `~/Work/Heethr/scripts/config-opencode.sh` to create the symlink.
6. Add a row to the per-project table above.
