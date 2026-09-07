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

      dnsEnabled = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Resolve names via aardvark. Disable to leave resolv.conf pointing at
          the container's own `--dns` servers, so lookups egress from its
          netns rather than the host's.
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
          script = "${lib.getExe pkgs.podman} network create --ignore --driver=${opts.driver} ${lib.optionalString (!opts.dnsEnabled) "--disable-dns "}${name}";
        };
      })
      cfg));
  };
}
