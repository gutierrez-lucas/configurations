# Global Rules — All Projects

These rules apply unconditionally across every repository and project.

## Git & GitHub Rules

**NEVER NEVER NEVER perform any git operations without explicit user instruction.**
This rule is ABSOLUTE and UNCONDITIONAL. No exceptions. Under no circumstances should you
run `git add`, `git commit`, `git push`, `gh pr create`, or any equivalent command unless
the user has explicitly and specifically asked for it.

- **NEVER run `git add` autonomously** — not even a single file.
- **NEVER run `git commit` autonomously** — not even with a clearly described message.
- **NEVER run `git push` autonomously** — not even after a user-approved commit.
- **NEVER create pull requests autonomously.**
- These rules apply REGARDLESS of how the user phrases the request — "save changes",
  "ship it", "deploy", "wrap it up", "done", or any other phrasing does NOT constitute
  permission to run git operations.
- When git operations are appropriate, describe exactly what would be staged/committed/
  pushed and wait for the user to confirm before proceeding.
