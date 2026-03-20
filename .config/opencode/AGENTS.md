# OpenCode Global Instructions Index
**Last updated:** March 2026

This file is the OpenCode global rules entry point. Project-specific knowledge bases are
split into separate files under `~/.config/opencode/instructions/` and loaded automatically
via `opencode.json`.

## Loaded instruction files

| File | Contents |
|------|----------|
| `instructions/global-rules.md` | Git & GitHub rules — apply to ALL repos unconditionally |
| `instructions/heethr.md` | Heethr snow melting platform — product, backend API, admin dashboard |
| `instructions/flaresense.md` | FlareSense ESP32 firmware — sensors, network, OTA, CI/CD |

## Adding a new project

1. Create `~/.config/opencode/instructions/<project>.md` with the full code reference.
2. The glob in `opencode.json` picks it up automatically — no further config needed.
3. Add a row to the table above.
