{ config, pkgs, ... }:
let
  secrets = import ../../secrets;
in
{
  virtualisation.oci-containers.containers.tdarr-node = {
    image = "ghcr.io/haveagitgat/tdarr_node:2.00.18";
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
      "${secrets.network.storage.hosts.valmar.address}:8267:8267"
    ];
    volumes = [
      "/storage/appdata/docker/tdarr/configs:/app/configs"
      "/storage/appdata/docker/tdarr/logs:/app/logs"
      "/mnt/appdata/temp/tdarr/cache:/temp"
      "/mnt/media:/media"
    ];
  };

  systemd.services.docker-tdarr-node.requires = [
    "mnt-appdata-temp.mount"
    "mnt-media.mount"
  ];
}