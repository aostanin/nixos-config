{
  lib,
  config,
  ...
}: let
  cfg = config.localModules.containers.networks;

  networkSubmodule = lib.types.submodule {
    options = {
      driver = lib.mkOption {
        type = lib.types.str;
        example = "bridge";
        description = ''
          Network driver.
        '';
      };
    };
  };
in {
  options.localModules.containers.networks = lib.mkOption {
    type = lib.types.attrsOf networkSubmodule;
    default = {};
    description = ''
      Network definitions.
    '';
  };

  config = {
    services.podman.networks = lib.mkMerge (lib.mapAttrsToList (name: opts: {
        ${name}.Driver = opts.driver;
      })
      cfg);
  };
}
