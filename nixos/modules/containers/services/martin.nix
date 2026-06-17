{
  lib,
  config,
  ...
}: let
  name = "martin";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/maplibre/martin:latest";
      raw.cmd = ["/tiles"];
      volumes.tiles = {
        destination = "/tiles";
        storageType = "bulk";
      };
      proxy = {
        enable = true;
        port = 3000;
      };
    };
  };
}
