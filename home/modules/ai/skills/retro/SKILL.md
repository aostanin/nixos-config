---
name: retro
description: Conduct a retrospective on a coding session: mine the transcript for what slowed the agent down and propose up to five environment fixes for the user to pick from.
disable-model-invocation: true
---

Retrospective on a coding session. The output is environment fixes for
future runs, not a narrative.

## Steps

1. Pick the session: the current one unless the user names a session, repo
   or date. If the current session hasn't been compacted, work from context
   and skip to step 3.

2. Find and condense the transcript:
   - claude-code: `~/.claude/projects/<cwd, / and . replaced by ->/*.jsonl`
   - maki: `~/.local/state/maki/sessions/*.jsonl`; the first line's `cwd`
     gives the project.

   If several match (parallel agents), pick the one whose latest user
   message matches your context; ask only if that isn't unique.

   Never read a transcript raw (they run 2–13 MB, mostly tool output).
   This keeps text, tool calls and failed results only, for both formats:

   ```sh
   jq -r '(.message // .d) as $m
     | select($m.role? == "user" or $m.role? == "assistant")
     | ((.timestamp // "")[11:19]) as $t
     | ($m.content | if type == "string" then [{type: "text", text: .}] else . end)[]
     | if .type == "text" then "\($t) \($m.role[0:1]): \(.text[0:300] | gsub("\n"; " "))"
       elif .type == "tool_use" then "\($t) > \(.name) \(.input | tostring | .[0:150])"
       elif .type == "tool_result" and .is_error then "\($t) ! \(.content | tostring | .[0:200])"
       else empty end' FILE
   ```

   If the output is still over ~100 KB, have a subagent read it and return
   the signals from step 3 with timestamps.

3. Find signals, each tied to a timestamp or quote:
   - the user correcting, interrupting, or denying a tool call
   - errors followed by retries of the same thing
   - long gaps between timestamps (claude-code only)
   - many searches and reads before the first useful edit

   Drop one-offs that wouldn't recur.

4. Choose where each fix lands:
   - **Automated check**: for mechanical mistakes (fixed pattern, banned
     call, import shape, file location). Read the repo's own lint/test/CI/
     pre-commit first; an existing but unwired or broken check is the
     finding. A repo with no guardrail at all is itself a finding.
   - **Steering file** (AGENTS.md/CLAUDE.md/rules): judgement calls only.
     These load on every request, so keep additions tiny. If a rule already
     covered it and was ignored, reword it or make it a check; don't
     duplicate it.
   - **Skill**: long or task-specific material. A skill that should have
     triggered but didn't needs a better description.
   - **Memory**: facts about one project or host. An index over its size
     limit is itself a finding.
   - **Pointer**: a fact or file that took long to find.
   - **Tool or access**: a cheaper command for repeated expensive calls, or
     information the agent couldn't reach (logs, a service, a config value).
   - **Steering bloat**: existing lines that belong in one of the above, or
     that don't change behaviour; delete or move them.

5. Present at most five, ranked by recurrence × cost, one line each:
   evidence → fix → target file.

6. Implement only the ones the user picks, following the `agent-context`
   skill. Global rules and skills are Nix-managed: edit
   `~/dev/personal/infra/nixos-config/home/modules/ai/{rules,skills}`, not
   the read-only copies under `~/.claude`, and `git add` new files or the
   flake won't include them.
