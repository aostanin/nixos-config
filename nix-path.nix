let
  sources = import ./nix/sources.nix { };
in
map (name: name + "=" + sources."${name}".url) (builtins.attrNames sources)
