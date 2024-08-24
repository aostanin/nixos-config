moduleArgs @ {...}: {
  imports = let
    containerLib = import ./lib.nix moduleArgs;
    args = moduleArgs // {inherit containerLib;};
  in [
    (import ./mealie.nix args)
    (import ./whoami.nix args)
  ];
}
