#!/bin/sh

commit_hash()
{
  repo=$1
  branch=$2
  echo $(git ls-remote -q "$repo" "refs/heads/$branch" | cut -f1)
}

github_tarball()
{
  path=$1
  branch=$2
  echo "https://github.com/$path/archive/$(commit_hash https://github.com/$path.git "$branch").tar.gz"
}

nixPath="[
  \"nixpkgs=$(github_tarball NixOS/nixpkgs nixos-$NIX_STATE_VERSION)\"
  \"unstable=$(github_tarball NixOS/nixpkgs master)\"
  \"nixos-hardware=$(github_tarball NixOS/nixos-hardware master)\"
  \"home-manager=$(github_tarball rycee/home-manager release-$NIX_STATE_VERSION)\"
]"
echo "$nixPath" | tee path.nix
