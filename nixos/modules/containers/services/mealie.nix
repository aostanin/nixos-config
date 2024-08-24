{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "mealie";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption name {};
    volumes = mkVolumesOption name {
      data = {
        user = toString 1000;
        group = toString 1000;
      };
    };
  };

  config = lib.mkIf (config.localModules.containers.enable && cfg.enable) {
    localModules.containers.services.${name} = {
      autoupdate = lib.mkDefault true;
      proxy = {
        enable = lib.mkDefault true;
        tailscale.enable = lib.mkDefault true;
        lan.enable = lib.mkDefault true;
        net.enable = lib.mkDefault true;
        net.auth = lib.mkDefault "authelia";
      };
    };

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "ghcr.io/mealie-recipes/mealie:latest";
        environment = {
          ALLOW_SIGNUP = "false";
          PUID = toString 1000;
          PGID = toString 1000;
          MAX_WORKERS = toString 1;
          WEB_CONCURRENCY = toString 1;
          BASE_URL = lib.head cfg.proxy.hosts;
        };
        volumes = ["${cfg.volumes.data.path}:/app/data"];
      }
      mkContainerDefaultConfig
      (mkContainerProxyConfig name cfg.proxy)
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.services."podman-${name}" = mkServiceProxyConfig name cfg.proxy;

    systemd.tmpfiles.rules = mkTmpfileVolumesConfig cfg.volumes;
  };
}
