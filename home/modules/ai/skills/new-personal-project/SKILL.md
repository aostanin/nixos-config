---
name: new-personal-project
description: Use when starting a new personal (non-work) project or repo under ~/dev/personal: picks a template from nix-templates, scaffolds it, creates the repo on the personal Forgejo and gets the first CI run green.
---

# New personal project

Personal only: templates carry personal keys, identifiers and caches. If the
target is under `~/dev/work` or for work, stop and say so.

Templates: `git+ssh://git@DOMAIN/aostanin/nix-templates`. Each one's
setup steps are its `welcomeText`, which `nix flake init` prints.

## Steps

1. Settle the name, directory (`~/dev/personal/<topic>/<name>`) and template:
   `nix flake show git+ssh://git@DOMAIN/aostanin/nix-templates`. If none
   fits, say so and start from `devenv init`; offer to turn the result into a
   template once it works.
2. In the empty directory: `git init -b main`, then
   `nix flake init -t git+ssh://git@DOMAIN/aostanin/nix-templates#<template>`.
3. Follow the welcomeText: replace the placeholders it names (check with
   `grep -rn`), run its setup commands.
4. Rewrite the template's `AGENTS.md` for this project. Load `agent-context`
   first.
5. Commit, then confirm with the user before creating the repo (private unless
   they say otherwise):
   `fj repo create <name> --private --ssh --push -d "<description>"`.
6. Set the Actions secrets the welcomeText lists:
   `fj actions secrets create -r aostanin/<name> <NAME> "$(cat <file>)"`.
   Delete any key file it says to delete.
7. Watch `fj actions tasks -r aostanin/<name>` until the first run passes; fix
   and push until it does. The task is done when CI is green, not at the push.

## Gaps found along the way

A fix that every project from this template would need belongs in
nix-templates, not just this project. Offer that change at the end.
