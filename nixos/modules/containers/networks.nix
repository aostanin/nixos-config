{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.localModules.containers.networks;

  networkSubmodule = lib.types.submodule {
    options = {
      driver = lib.mkOption {
        type = lib.types.str;
        default = "bridge";
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
    systemd.services = lib.mkIf config.localModules.containers.enable (lib.mkMerge (lib.mapAttrsToList (name: opts: {
        "podman-${name}-network" = {
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            SyslogIdentifier = "%N";
          };
          unitConfig = {
            "RequiresMountsFor" = "%t/containers";
          };
          wantedBy = ["multi-user.target"];
          script = "${lib.getExe pkgs.podman} network create --ignore --driver=${opts.driver} ${name}";
        };
      })
      cfg));
  };
}
