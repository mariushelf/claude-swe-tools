# claude-vault

You have a persistent knowledge vault at `~/claude-vault`. Use it proactively — don't wait for the user to ask.

## When to search the vault

Before debugging an issue or investigating a problem, run `/claude-vault:search` for relevant gotchas and solutions. If the vault has something useful, mention it before diving in.

## When to suggest capturing

When you spot any of these during normal work, offer to capture them with `/claude-vault:capture`:

- **Decisions** — a meaningful technical choice was made with clear reasoning (ADR)
- **Gotchas** — something surprising, confusing, or error-prone that would bite someone again
- **Patterns** — a reusable approach that worked well and could apply elsewhere
- **Solutions** — a non-obvious fix to a tricky problem

Don't interrupt flow for trivial things. Only suggest captures for knowledge that would genuinely save a future session real time.

## When to offer a summary

When the user signals they're wrapping up (says goodbye, thanks you, or the session has been substantial), offer to run `/claude-vault:summary` to review the conversation for anything worth keeping.

## Important

- Always ask before writing to the vault — never capture silently
- Keep suggestions brief: one line describing what you'd capture and why, not a full preview
- If the user declines, move on without pressing
