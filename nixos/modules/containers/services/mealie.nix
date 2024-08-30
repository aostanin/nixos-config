{
  lib,
  config,
  ...
}: let
  name = "mealie";
  cfg = config.localModules.containers.services.${name};
  uid = toString config.localModules.containers.uid;
  gid = toString config.localModules.containers.gid;
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/mealie-recipes/mealie:latest";
      raw.environment = {
        ALLOW_SIGNUP = "false";
        PUID = uid;
        PGID = gid;
        MAX_WORKERS = "1";
        WEB_CONCURRENCY = "1";
        BASE_URL = "${lib.head (config.lib.containers.mkHosts name)}";
      };
      volumes.data = {
        destination = "/app/data";
        user = uid;
        group = gid;
      };
      proxy.enable = true;
    };
  };
}
