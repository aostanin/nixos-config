{ config, pkgs, ... }:
let
  secrets = import ../../secrets;
in
{
  virtualisation.oci-containers.containers.tdarr-node = {
    image = "ghcr.io/haveagitgat/tdarr_node";
    environment = {
      TZ = config.time.timeZone;
      PUID = "1000";
      GUID = "1000";
      UMASK_SET = "002";
      nodeID = "valmar";
      nodeIP = secrets.network.storage.hosts.valmar.address;
      serverID = "elena";
      serverIP = secrets.network.storage.hosts.elena.address;
      serverPort = "8266";
    };
    ports = [
      "8267:8267"
    ];
    volumes = [
      "/storage/appdata/docker/tdarr/configs:/app/configs"
      "/storage/appdata/docker/tdarr/logs:/app/logs"
      "/mnt/appdata/temp/tdarr/cache:/temp"
      "/mnt/media:/media"
    ];
  };
}
