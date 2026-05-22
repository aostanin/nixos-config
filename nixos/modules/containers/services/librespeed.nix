{
  lib,
  config,
  ...
}: let
  name = "librespeed";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/librespeed/speedtest:latest";
      healthcheck = {
        cmd = "curl -f http://localhost:8080/";
        startPeriod = "30s";
      };
      proxy = {
        enable = true;
        port = 8080;
      };
    };
  };
}
