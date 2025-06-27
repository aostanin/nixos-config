{
  lib,
  config,
  ...
}: let
  name = "netbootxyz";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    uid = lib.mkOption {
      type = lib.types.int;
      default = config.localModules.containers.uid;
    };

    gid = lib.mkOption {
      type = lib.types.int;
      default = config.localModules.containers.gid;
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/netbootxyz/netbootxyz:latest";
      raw.environment = {
        PUID = toString cfg.uid;
        PGID = toString cfg.gid;
      };
      raw.ports = ["69:69/udp"];
      volumes = {
        config = {
          destination = "/config";
          user = toString cfg.uid;
          group = toString cfg.gid;
        };
        assets = {
          destination = "/assets";
          user = toString cfg.uid;
          group = toString cfg.gid;
        };
      };
      proxy = {
        enable = true;
        port = 3000;
      };
    };
  };
}
