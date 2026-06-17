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

    # The dongle sits behind a flaky dock USB hub that occasionally drops off
    # the bus for a few seconds. Retry indefinitely at a calm pace so a brief
    # disconnect self-heals instead of tripping the start-limit and wedging.
    systemd.services."podman-${name}" = {
      startLimitIntervalSec = 0;
      serviceConfig.RestartSec = lib.mkForce "15s";
    };
  };
}
