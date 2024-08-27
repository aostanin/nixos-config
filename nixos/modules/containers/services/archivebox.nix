{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "archivebox";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption name {port = 8000;};
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
        image = "docker.io/archivebox/archivebox:master";
        cmd = ["server" "--quick-init" "0.0.0.0:8000"];
        environment = let
          userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36";
        in {
          SAVE_ARCHIVE_DOT_ORG = "False";
          PUBLIC_INDEX = "False";
          PUBLIC_SNAPSHOTS = "False";
          PUBLIC_ADD_VIEW = "False";
          CURL_USER_AGENT = userAgent;
          WGET_USER_AGENT = userAgent;
          CHROME_USER_AGENT = userAgent;
        };
        volumes = ["${cfg.volumes.data.path}:/data"];
      }
      mkContainerDefaultConfig
      (mkContainerProxyConfig name cfg.proxy)
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.services."podman-${name}" = mkServiceProxyConfig name cfg.proxy;
  };
}
