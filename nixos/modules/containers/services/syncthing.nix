{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "syncthing";
  cfg = config.localModules.containers.services.${name};
  uid = toString config.localModules.containers.uid;
  gid = toString config.localModules.containers.gid;
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption name {port = 8384;};
    volumes = mkVolumesOption name {
      config = {
        user = uid;
        group = gid;
      };
      sync = {
        user = uid;
        group = gid;
      };
    };
  };

  config = lib.mkIf (config.localModules.containers.enable && cfg.enable) {
    localModules.containers.services.${name} = {
      autoupdate = lib.mkDefault true;
      proxy = {
        enable = lib.mkDefault true;
        tailscale.enable = lib.mkDefault true;
      };
    };

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "docker.io/syncthing/syncthing:latest";
        ports = [
          "8384" # Web UI
          "22000:22000/tcp" # TCP file transfers
          "22000:22000/udp" # QUIC file transfers
          "21027:21027/udp" # Receive local discovery broadcasts
        ];
        environment = {
          PUID = uid;
          PGID = gid;
        };
        volumes = [
          "${cfg.volumes.config.path}:/var/syncthing/config"
          "${cfg.volumes.sync.path}:/sync"
        ];
      }
      mkContainerDefaultConfig
      (mkContainerProxyConfig name cfg.proxy)
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.services."podman-${name}" = mkServiceProxyConfig name cfg.proxy;

    systemd.tmpfiles.rules = mkTmpfileVolumesConfig cfg.volumes;
  };
}
