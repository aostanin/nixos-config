{
  lib,
  config,
  ...
}: let
  name = "hauk";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/bilde2910/hauk:stable-1.x";
      volumes.config.destination = "/etc/hauk";
      proxy = {
        enable = true;
        port = 80;
        default.enable = true;
      };
    };
  };
}
