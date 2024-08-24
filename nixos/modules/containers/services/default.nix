moduleArgs @ {...}: {
  imports = let
    containerLib = import ./lib.nix moduleArgs;
    args = moduleArgs // {inherit containerLib;};
  in [
    (import ./authelia.nix args)
    (import ./mealie.nix args)
    (import ./miniflux.nix args)
    (import ./whoami.nix args)
    (import ./uptime-kuma.nix args)
  ];
}
