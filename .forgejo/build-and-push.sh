#!/usr/bin/env bash
# Build every nixosConfiguration matching $1 (a Nix system, e.g. x86_64-linux)
# and push each toplevel's closure to the Attic cache.
set -euo pipefail

system="${1:?usage: build-and-push.sh <system>}"

# Decrypt git-agecrypt'ed secrets: checkout has ciphertext, re-smudge with the
# CI identity provisioned via sops on the runner host.
git config filter.git-agecrypt.required true
git config filter.git-agecrypt.smudge "git-agecrypt smudge -f %f"
git config filter.git-agecrypt.clean "git-agecrypt clean -f %f"
git config git-agecrypt.config.identity /run/secrets/forgejo/agecrypt_identity
rm -rf secrets
git checkout -- secrets/

domain=$(nix eval --raw --impure --expr '(import ./secrets).domain')
endpoint="https://attic.${domain}/"
server="elena"
cache="aostanin"

run_attic() { nix run --inputs-from . nixpkgs#attic-client -- "$@"; }

: "${ATTIC_TOKEN:?ATTIC_TOKEN is not set}"
run_attic login "$server" "$endpoint" "$ATTIC_TOKEN"

hosts=$(nix eval --raw .#nixosConfigurations --apply \
  "cfgs: builtins.concatStringsSep \" \" (builtins.filter (n: cfgs.\${n}.pkgs.stdenv.hostPlatform.system == \"$system\") (builtins.attrNames cfgs))")

echo "Building hosts for $system:$hosts"

for host in $hosts; do
  echo "::group::$host"
  out=$(nix build --no-link --print-out-paths \
    ".#nixosConfigurations.${host}.config.system.build.toplevel")
  run_attic push "${server}:${cache}" $out
  echo "::endgroup::"
done
