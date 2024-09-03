{
  lib,
  config,
  ...
}: let
  name = "tdarr";
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
      raw.image = "ghcr.io/haveagitgat/tdarr:latest";
      raw.environment = {
        PUID = toString cfg.uid;
        PGID = toString cfg.gid;
        UMASK_SET = "002";
        serverIP = "0.0.0.0";
        serverPort = "8266";
        webUIPort = "8265";
        internalNode = "true";
        inContainer = "true";
        nodeName = config.networking.hostName;
      };
      volumes = {
        server = {
          destination = "/app/server";
          user = toString cfg.uid;
          group = toString cfg.gid;
        };
        configs = {
          destination = "/app/configs";
          user = toString cfg.uid;
          group = toString cfg.gid;
        };
        logs = {
          destination = "/app/logs";
          user = toString cfg.uid;
          group = toString cfg.gid;
        };
        temp = {
          destination = "/temp";
          storageType = "temp";
          user = toString cfg.uid;
          group = toString cfg.gid;
        };
      };
      raw.volumes = cfg.volumes;
      proxy = {
        enable = true;
        port = 8265;
      };
    };
  };
}
