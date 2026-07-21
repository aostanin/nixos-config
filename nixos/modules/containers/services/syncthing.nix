{
  lib,
  config,
  ...
}: let
  name = "syncthing";
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

    port = lib.mkOption {
      type = lib.types.port;
      default = 22000;
      description = "Host port for sync transfers (remap when another syncthing runs on the host).";
    };

    localDiscovery = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Publish the local discovery port (only one instance per host can).";
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/syncthing/syncthing:latest";
      raw.ports =
        [
          "8384" # Web UI
          "${toString cfg.port}:22000/tcp" # TCP file transfers
          "${toString cfg.port}:22000/udp" # QUIC file transfers
        ]
        ++ lib.optional cfg.localDiscovery "21027:21027/udp"; # Receive local discovery broadcasts
      raw.environment = {
        PUID = toString cfg.uid;
        PGID = toString cfg.gid;
      };
      volumes = {
        config = {
          destination = "/var/syncthing/config";
          user = toString cfg.uid;
          group = toString cfg.gid;
        };
        sync = {
          destination = "/sync";
          user = toString cfg.uid;
          group = toString cfg.gid;
        };
      };
      healthcheck = {
        cmd = "curl -fkLsS -m 2 127.0.0.1:8384/rest/noauth/health | grep -o --color=never OK";
        startPeriod = "30s";
      };
      proxy = {
        enable = true;
        port = 8384;
      };
    };
  };
}
