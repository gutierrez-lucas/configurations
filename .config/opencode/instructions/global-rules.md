# Global Rules — All Projects

These rules apply unconditionally across every repository and project.

## Git & GitHub Rules

- **NEVER run `git push` autonomously.** Always stop and ask the user before pushing to any remote.
- **NEVER run `git add` or `git commit` autonomously.** Always ask the user before staging or committing any changes.
- **NEVER create pull requests autonomously.** Always ask before running `gh pr create` or any equivalent.
- Before any git add / commit / push / PR action, explicitly describe what will be staged/committed/pushed and ask for confirmation.
- This rule is unconditional — it applies regardless of how the user phrases the request (e.g. "save changes", "ship it", "deploy", etc.).
