{
  lib,
  config,
  ...
}: let
  name = "sonarr";
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

    volumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra volumes to bind to the container.";
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/linuxserver/sonarr:latest";
      networks = ["arr"];
      raw.environment = {
        PUID = toString cfg.uid;
        PGID = toString cfg.gid;
      };
      volumes.config = {
        destination = "/config";
        user = toString cfg.uid;
        group = toString cfg.gid;
      };
      raw.volumes = cfg.volumes;
      proxy = {
        enable = true;
      };
    };
  };
}
