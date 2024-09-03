{
  lib,
  config,
  ...
}: let
  name = "mealie";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    uid = lib.mkOption {
      type = lib.types.int;
      default = config.localModules.containers.uid;
    };

    gid = lib.mkOption {
      type = lib.types.int;
      default = config.localModules.containers.gid;
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/mealie-recipes/mealie:latest";
      raw.environment = {
        ALLOW_SIGNUP = "false";
        PUID = toString cfg.uid;
        PGID = toString cfg.gid;
        MAX_WORKERS = "1";
        WEB_CONCURRENCY = "1";
        BASE_URL = lib.head (config.lib.containers.mkHosts name);
      };
      volumes.data = {
        destination = "/app/data";
        user = toString cfg.uid;
        group = toString cfg.gid;
      };
      proxy.enable = true;
    };
  };
}
