{
  lib,
  config,
  ...
}: let
  name = "tasmoadmin";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/tasmoadmin/tasmoadmin:latest";
      volumes.data.destination = "/data";
      proxy = {
        enable = true;
        port = 80;
      };
    };
  };
}
