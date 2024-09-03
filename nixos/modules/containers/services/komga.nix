{
  lib,
  config,
  ...
}: let
  name = "komga";
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
      raw.image = "docker.io/gotson/komga:latest";
      raw.user = "${toString cfg.uid}:${toString cfg.gid}";
      volumes.config = {
        destination = "/config";
        user = toString cfg.uid;
        group = toString cfg.gid;
      };
      raw.volumes = cfg.volumes;
      proxy = {
        enable = true;
        port = 25600;
      };
    };
  };
}
