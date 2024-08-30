{
  lib,
  config,
  ...
}: let
  name = "syncthing";
  cfg = config.localModules.containers.services.${name};
  uid = toString config.localModules.containers.uid;
  gid = toString config.localModules.containers.gid;
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
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
        PUID = uid;
        PGID = gid;
      };
      volumes = {
        config = {
          destination = "/var/syncthing/config";
          user = uid;
          group = gid;
        };
        sync = {
          destination = "/sync";
          user = uid;
          group = gid;
        };
      };
      proxy = {
        enable = true;
        port = 8384;
      };
    };
  };
}
