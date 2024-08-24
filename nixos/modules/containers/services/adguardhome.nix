{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "adguardhome";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption name {port = 80;};
    adminProxy = mkProxyOption "${name}-admin" {port = 3000;};
    volumes = mkVolumesOption name {
      work = {};
      conf = {};
    };

    dnsPort = lib.mkOption {
      type = lib.types.int;
      default = 53;
    };
  };

  config = lib.mkIf (config.localModules.containers.enable && cfg.enable) {
    localModules.containers.services.${name} = {
      autoupdate = lib.mkDefault true;
      proxy = {
        enable = lib.mkDefault true;
        tailscale.enable = lib.mkDefault true;
      };
      adminProxy = {
        enable = lib.mkDefault true;
        tailscale.enable = lib.mkDefault true;
      };
    };

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "docker.io/adguard/adguardhome:latest";
        ports = [
          "${toString cfg.dnsPort}:53/tcp"
          "${toString cfg.dnsPort}:53/udp"
        ];
        volumes = [
          "${cfg.volumes.work.path}:/opt/adguardhome/work"
          "${cfg.volumes.conf.path}:/opt/adguardhome/conf"
        ];
      }
      mkContainerDefaultConfig
      (mkContainerProxyConfig name cfg.proxy)
      (mkContainerProxyConfig "${name}-admin" cfg.adminProxy)
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.services."podman-${name}" = mkServiceProxyConfig name cfg.proxy;

    systemd.tmpfiles.rules = mkTmpfileVolumesConfig cfg.volumes;
  };
}
