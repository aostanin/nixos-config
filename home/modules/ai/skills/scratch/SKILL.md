---
name: scratch
description: Use when asked to try, prototype, spike or experiment with something that shouldn't be committed to the current repo, or when the user mentions scratch/tries. Creates a dated experiment dir in the nearest scratch/.
---

# Scratch experiments

## Find the scratch root

Walk up from the cwd and use the first `<ancestor>/scratch/` that is not
inside a git work tree (a repo's own `scratch/` is project code, not this).
Stop at `$HOME`; if none is found, ask where it should go.

```sh
d=$PWD
while [ "$d" != "$HOME" ] && [ "$d" != / ]; do
  if [ -d "$d/scratch" ] && ! git -C "$d/scratch" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "$d/scratch"; break
  fi
  d=$(dirname "$d")
done
```

## Create or reuse

- First `ls` the root: if an experiment on the same topic exists, continue it.
- New ones are `<root>/YYYY-MM-DD-<slug>`, slug lowercase-hyphenated, prefixed
  with the related project when there is one (`2026-10-07-usebitcoin-fee-test`).
- Experimenting on the current repo's code: `git worktree add --detach <dir>`
  from the repo instead of copying files. Never commit or push from it unless asked.
- Otherwise a plain directory.
- Put a `NOTES.md` in it: one line on the goal (and source repo + commit for
  worktrees); append findings when done.

## Lifecycle

- Delete worktree experiments with `git worktree remove`, never `rm -rf`.
- Promoting an experiment to a project is the user's call; move it beside the
  scratch root (`git worktree move` for worktrees).
