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
      proxy = {
        enable = true;
      };
    };
  };
}
