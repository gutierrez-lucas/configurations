# Global Rules — All Projects

These rules apply unconditionally across every repository and project.

## Git & GitHub Rules

**Every git operation must come from the explicit will of the user. No exceptions.**

- **NEVER run `git add` autonomously** — not even a single file. Staging requires explicit user instruction.
- **NEVER run `git commit` autonomously** — not even with a clearly described message. Committing requires explicit user instruction.
- **NEVER run `git push` autonomously** — not even after a user-approved commit. Pushing requires explicit user instruction.
- **NEVER create pull requests autonomously.** Never run `gh pr create` or any equivalent without explicit instruction.
- These rules are unconditional. They apply regardless of how the user phrases a request — "save changes", "ship it", "deploy", "wrap it up", "done", or any other phrasing does NOT constitute permission to run git operations.
- When git operations are appropriate, describe exactly what would be staged/committed/pushed and wait for the user to say so explicitly.
