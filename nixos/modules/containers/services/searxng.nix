{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "searxng";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption "searx" {};
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
        lan.enable = lib.mkDefault true;
        net = {
          enable = lib.mkDefault true;
          auth = lib.mkDefault "authelia";
        };
      };
    };

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "docker.io/searxng/searxng:latest";
        volumes = ["${cfg.volumes.data.path}:/etc/searxng"];
      }
      mkContainerDefaultConfig
      (mkContainerProxyConfig name cfg.proxy)
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.services."podman-${name}" = mkServiceProxyConfig name cfg.proxy;

    systemd.tmpfiles.rules = mkTmpfileVolumesConfig cfg.volumes;
  };
}
