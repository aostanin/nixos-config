{
  lib,
  config,
  ...
}: let
  name = "prowlarr";
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
      raw.image = "docker.io/linuxserver/prowlarr:latest";
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
      proxy = {
        enable = true;
      };
    };
  };
}
