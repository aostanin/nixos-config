---
name: agent-context
description: Use before writing or editing any file meant to be read by an agent (AGENTS.md, CLAUDE.md, skills, rules, prompts, tool descriptions, memory notes). Keeps them terse.
paths:
  - "**/AGENTS.md"
  - "**/CLAUDE.md"
  - "**/SKILL.md"
  - "**/.claude/rules/*.md"
  - "**/ai/rules/*.md"
---

# Writing agent context

Everything an agent reads costs tokens each time it's loaded, and most of it
(AGENTS.md, rules, tool descriptions) is loaded on every request.

- Only what the agent can't get from the code, git history or general
  knowledge: non-obvious constraints, conventions, gotchas, commands.
- Terse bullets. No intros, motivation or closing summaries; an example only
  when the rule is ambiguous without one.
- Long or task-specific material belongs in a skill, not AGENTS.md. A skill's
  description is always loaded, so make it say exactly when to use it.
- Edit or delete existing lines instead of appending.
