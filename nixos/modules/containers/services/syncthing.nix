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
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/syncthing/syncthing:latest";
      raw.ports = [
        "8384" # Web UI
        "22000:22000/tcp" # TCP file transfers
        "22000:22000/udp" # QUIC file transfers
        "21027:21027/udp" # Receive local discovery broadcasts
      ];
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
      proxy = {
        enable = true;
        port = 8384;
      };
    };
  };
}
