{
  lib,
  config,
  ...
}: let
  name = "scrutiny";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/analogj/scrutiny:master-omnibus";
      volumes = {
        config.destination = "/opt/scrutiny/config";
        influxdb.destination = "/opt/scrutiny/influxdb";
      };
      proxy = {
        enable = true;
        port = 8080;
      };
    };
  };
}
