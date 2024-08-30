{
  lib,
  config,
  ...
}: let
  name = "influxdb";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/library/influxdb:2";
      volumes = {
        data.destination = "/var/lib/influxdb2";
        config.destination = "/etc/influxdb2";
      };
      proxy = {
        enable = true;
        port = 8086;
      };
    };
  };
}
