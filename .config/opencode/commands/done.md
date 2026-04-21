---
description: Save session to Engram memory and close session
agent: gentleman
---

Save this session to persistent memory and close it. Follow these steps exactly:

1. Call `mem_session_summary` with a full structured summary of everything discussed in this session. Use this exact format:

   ## Goal
   [One sentence: what were we working on this session]

   ## Instructions
   [User preferences or constraints discovered — skip if none]

   ## Discoveries
   - [Technical findings, gotchas, non-obvious learnings]

   ## Accomplished
   - ✅ [Completed items with key implementation details]
   - 🔲 [Identified but not yet done — for next session]

   ## Relevant Files
   - path/to/file — [what it does or what changed]

2. Call `mem_session_end` to mark the session as closed.

3. Confirm to the user with this exact message:
   "Session saved to Engram. You can now close OpenCode."

Be thorough in the summary — the next session starts completely blind without it.
