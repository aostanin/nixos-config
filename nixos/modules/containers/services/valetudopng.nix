{
  lib,
  config,
  ...
}: let
  name = "valetudopng";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/erkexzcx/valetudopng:latest";
      volumes.config.destination = "/config";
      raw.cmd = ["-config" "/config/config.yml"];
      proxy = {
        enable = true;
        port = 3000;
      };
    };
  };
}
