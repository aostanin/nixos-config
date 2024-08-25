{
  lib,
  pkgs,
  config,
  containerLib,
  secrets,
  ...
}:
with containerLib; let
  name = "zwift-offline";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption name {
      port = 443;
      scheme = "https";
    };
    volumes = mkVolumesOption name {
      storage = {};
    };
  };

  config = lib.mkIf (config.localModules.containers.enable && cfg.enable) {
    localModules.containers.services.${name} = {
      autoupdate = lib.mkDefault true;
      proxy = {
        enable = lib.mkDefault true;
        tailscale.enable = lib.mkDefault true;
        lan.enable = lib.mkDefault true;
        hosts = [
          "us-or-rly101.zwift.com"
          "secure.zwift.com"
          "cdn.zwift.com"
          "launcher.zwift.com"
        ];
      };
    };

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "docker.io/zoffline/zoffline:latest";
        ports = [
          "3024:3024/udp"
          "3025:3025"
        ];
        volumes = let
          serverIp = pkgs.writeTextFile {
            name = "server-ip.txt";
            text = secrets.network.home.hosts.${config.networking.hostName}.address;
          };
        in [
          "${cfg.volumes.storage.path}:/usr/src/app/zwift-offline/storage"
          "${serverIp}:/usr/src/app/zwift-offline/storage/server-ip.txt"
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
