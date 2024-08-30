{
  lib,
  config,
  ...
}: let
  name = "changedetection";
  cfg = config.localModules.containers.services.${name};
  uid = toString config.localModules.containers.uid;
  gid = toString config.localModules.containers.gid;
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/dgtlmoon/changedetection.io:latest";
      networks = [name];
      raw.dependsOn = ["${name}-playwright-chrome"];
      raw.environment = {
        PUID = uid;
        PGID = gid;
        PLAYWRIGHT_DRIVER_URL = "ws://${name}-playwright-chrome:3000/?stealth=1&--disable-web-security=true";
        HIDE_REFERER = "true";
      };
      volumes.data = {
        destination = "/datastore";
        user = uid;
        group = gid;
      };
      proxy = {
        enable = true;
        port = 5000;
      };
    };

    localModules.containers.containers."${name}-playwright-chrome" = {
      raw.image = "docker.io/browserless/chrome:latest";
      networks = [name];
      raw.environment = {
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
    };
  };
}
