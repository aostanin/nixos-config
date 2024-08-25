{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "influxdb";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption name {port = 8086;};
    volumes = mkVolumesOption name {
      data = {};
      config = {};
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
        image = "docker.io/library/influxdb:2";
        volumes = [
          "${cfg.volumes.data.path}:/var/lib/influxdb2"
          "${cfg.volumes.config.path}:/etc/influxdb2"
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
