{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "changedetection";
  cfg = config.localModules.containers.services.${name};
  uid = toString config.localModules.containers.uid;
  gid = toString config.localModules.containers.gid;
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption name {port = 5000;};
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

    localModules.containers.networks.${name} = {};

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "ghcr.io/dgtlmoon/changedetection.io:latest";
        dependsOn = ["${name}-playwright-chrome"];
        environment = {
          PUID = uid;
          PGID = gid;
          PLAYWRIGHT_DRIVER_URL = "ws://${name}-playwright-chrome:3000/?stealth=1&--disable-web-security=true";
          HIDE_REFERER = "true";
        };
        volumes = [
          "${cfg.volumes.data.path}:/datastore"
        ];
        extraOptions = ["--network=${name}"];
      }
      mkContainerDefaultConfig
      (mkContainerProxyConfig name cfg.proxy)
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    virtualisation.oci-containers.containers."${name}-playwright-chrome" = lib.mkMerge [
      {
        image = "docker.io/browserless/chrome:latest";
        environment = {
          SCREEN_WIDTH = "1920";
          SCREEN_HEIGHT = "1024";
          SCREEN_DEPTH = "16";
          ENABLE_DEBUGGER = "false";
          PREBOOT_CHROME = "false";
          CONNECTION_TIMEOUT = "300000";
          CHROME_REFRESH_TIME = "600000";
          DEFAULT_BLOCK_ADS = "false";
          DEFAULT_STEALTH = "true";
        };
        extraOptions = ["--network=${name}"];
      }
      mkContainerDefaultConfig
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.services."podman-${name}" = lib.mkMerge [
      (mkServiceProxyConfig name cfg.proxy)
      (mkServiceNetworksConfig name [name])
    ];
    systemd.services."podman-${name}-playwright-chrome" = mkServiceNetworksConfig name [name];

    systemd.tmpfiles.rules = mkTmpfileVolumesConfig cfg.volumes;
  };
}
