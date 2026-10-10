---
name: prs-and-issues
description: Use when writing or editing a pull request or issue (title or body) on GitHub, Forgejo or Gitea.
---

# PRs and issues

**Language:** match the repo; some use English, some Japanese. Check recent
PRs and issues first, and use that language for titles, bodies and headings.

**Templates win.** Look in `.github/`, `.gitea/`, `.forgejo/`, `docs/` and the
repo root for `PULL_REQUEST_TEMPLATE*`/`pull_request_template*` and
`ISSUE_TEMPLATE/` (including YAML issue forms). With one: keep its sections
verbatim and in order and fill every one; a few words on why a section doesn't
apply beats deleting it. Leave checklists and HTML comments in place, tick only
what was done, and add no sections of your own.

## PRs

Title: short and specific, like a commit subject. Without a template:

```markdown
## Summary

Cache parsed configs; parsing was 40% of p99.

## Test plan

- `pytest tests/config/`
- Verified SIGHUP flush manually
```

- Summary: what changed and why, one sentence where possible.
- Test plan: only commands actually run and checks actually done. If nothing
  was verified, say so.
- No "Changes" section listing the diff, no motivation paragraphs, no
  restating the ticket, no closing summary.

## Issues

- Search existing issues first; comment on a duplicate rather than opening a
  new one.
- Title states the problem, not the fix: "Login fails when the password
  contains a `+`", not "Fix login".
- Bug: what happened, what was expected, how to reproduce, evidence (exact
  errors, versions). Feature: what's needed and why, in a few lines.
- Only observed facts; label guesses as guesses. No proposed-solution essay
  unless asked.
