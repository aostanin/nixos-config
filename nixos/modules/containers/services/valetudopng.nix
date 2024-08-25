{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "valetudopng";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption name {port = 3000;};
    volumes = mkVolumesOption name {
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
        image = "ghcr.io/erkexzcx/valetudopng:latest";
        volumes = [
          "${cfg.volumes.config.path}:/config"
        ];
        cmd = ["-config" "/config/config.yml"];
      }
      mkContainerDefaultConfig
      (mkContainerProxyConfig name cfg.proxy)
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.services."podman-${name}" = mkServiceProxyConfig name cfg.proxy;

    systemd.tmpfiles.rules = mkTmpfileVolumesConfig cfg.volumes;
  };
}
