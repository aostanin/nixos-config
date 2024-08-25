{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "tasmoadmin";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption name {port = 80;};
    volumes = mkVolumesOption name {
      data = {};
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
        image = "ghcr.io/tasmoadmin/tasmoadmin:latest";
        volumes = [
          "${cfg.volumes.data.path}:/data"
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
