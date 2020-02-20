#!/bin/sh

nixPath="[
  \"nixpkgs=https://github.com/NixOS/nixpkgs/archive/$(git ls-remote -q https://github.com/NixOS/nixpkgs.git refs/heads/nixos-19.09 | cut -f1).tar.gz\"
  \"home-manager=https://github.com/rycee/home-manager/archive/$(git ls-remote -q https://github.com/rycee/home-manager.git refs/heads/release-19.09 | cut -f1).tar.gz\"
  \"nixos-hardware=https://github.com/NixOS/nixos-hardware/archive/$(git ls-remote -q https://github.com/NixOS/nixos-hardware.git refs/heads/master | cut -f1).tar.gz\"
]"
echo "$nixPath" | tee path.nix
