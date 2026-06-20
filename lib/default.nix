{
  lib,
  pkgs,
}:
builtins.foldl' (acc: m: acc // import m {inherit lib pkgs;}) {} [
  ./meta.nix
  ./ingress.nix
]
