{
  lib,
  config,
  ...
}: let
  name = "jellyfin";
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

    devices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra devices to bind to the container.";
    };

    volumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra volumes to bind to the container.";
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/jellyfin/jellyfin:latest";
      raw.user = "${toString cfg.uid}:${toString cfg.gid}";
      raw.ports = ["7359:7359/udp"];
      volumes = {
        config = {
          destination = "/config";
          user = toString cfg.uid;
          group = toString cfg.gid;
        };
        transcoding-temp = {
          destination = "/transcoding-temp";
          storageType = "temp";
          user = toString cfg.uid;
          group = toString cfg.gid;
        };
      };
      raw.volumes = cfg.volumes;
      raw.extraOptions = lib.map (d: "--device=${d}") cfg.devices;
      proxy = {
        enable = true;
        port = 8096;
      };
    };
  };
}
