{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "mealie";
  cfg = config.localModules.containers.services.${name};
  uid = toString config.localModules.containers.uid;
  gid = toString config.localModules.containers.gid;
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption name {};
    volumes = mkVolumesOption name {
      data = {
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
        image = "ghcr.io/mealie-recipes/mealie:latest";
        environment = {
          ALLOW_SIGNUP = "false";
          PUID = uid;
          PGID = gid;
          MAX_WORKERS = "1";
          WEB_CONCURRENCY = "1";
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
