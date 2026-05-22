{
  lib,
  config,
  ...
}: let
  name = "jellyseerr";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/fallenbagel/jellyseerr:latest";
      networks = ["arr"];
      volumes.config.destination = "/app/config";
      healthcheck = {
        cmd = "wget --no-verbose --tries=1 --spider http://localhost:5055/api/v1/status";
        startPeriod = "30s";
      };
      proxy = {
        enable = true;
      };
    };
  };
}
