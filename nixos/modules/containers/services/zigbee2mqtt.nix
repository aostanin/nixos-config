{
  lib,
  config,
  ...
}: let
  name = "zigbee2mqtt";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    adapterPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to the Zigbee adapter, usually /dev/serial/by-id/<DEVICE>.";
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/koenkk/zigbee2mqtt:latest";
      volumes.data.destination = "/app/data";
      raw.volumes = ["/run/udev:/run/udev:ro"];
      raw.extraOptions = ["--device" "${cfg.adapterPath}:/dev/ttyACM0"];
      proxy = {
        enable = true;
        port = 8080;
      };
    };
  };
}
