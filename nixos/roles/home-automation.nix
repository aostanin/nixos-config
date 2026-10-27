{
  config,
  lib,
  ...
}: let
  cfg = config.roles.home-automation;
  slice = "roles-home-automation";

  containers = [
    "home-assistant"
    "mosquitto"
    "zigbee2mqtt"
    "frigate"
    "ir-mqtt-bridge"
    "daikin-cleaner-mqtt"
    "valetudopng"
    "tasmoadmin"
  ];
in {
  options.roles.home-automation = {
    enable = lib.mkEnableOption "Home Assistant with MQTT, Zigbee and camera recording";

    zigbeeAdapter = lib.mkOption {
      type = lib.types.str;
      example = "/dev/serial/by-id/usb-example-if00-port0";
    };

    frigateDevices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["/dev/dri/renderD128"];
      description = "Devices for Frigate's detectors and hardware decoding.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.localModules.containers.enable;
        message = "roles.home-automation runs on localModules.containers";
      }
    ];

    localModules.containers.services = lib.mkMerge [
      (lib.genAttrs containers (_: {enable = true;}))
      {
        zigbee2mqtt.adapterPath = cfg.zigbeeAdapter;
        frigate.devices = cfg.frigateDevices;
      }
    ];

    localModules.containers.containers = lib.genAttrs containers (_: {slice = "${slice}.slice";});

    systemd.slices.${slice} = {};
  };
}
