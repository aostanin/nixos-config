{
  lib,
  pkgs,
  config,
  secrets,
  ...
}: let
  name = "ir-mqtt-bridge";
  cfg = config.localModules.containers.services.${name};

  devicesFile =
    (pkgs.formats.toml {}).generate "devices.toml"
    {device = secrets.irMqttBridge.devices;};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."forgejo/registry_token" = {};
    sops.secrets."containers/ir-mqtt-bridge/home_assistant_token" = {};

    sops.templates."${name}.env".content = ''
      HOME_ASSISTANT_TOKEN=${config.sops.placeholder."containers/ir-mqtt-bridge/home_assistant_token"}
    '';

    localModules.containers.containers.${name} = {
      raw.image = "${secrets.forgejo.registry}/${secrets.forgejo.username}/ir-mqtt:latest";
      raw.login = {
        inherit (secrets.forgejo) registry username;
        passwordFile = config.sops.secrets."forgejo/registry_token".path;
      };
      raw.environment = {
        RUST_LOG = "debug";
        MQTT_HOST = secrets.mqtt.host;
        HOME_ASSISTANT_URL = secrets.homeAssistant.baseUrl;
        DEVICES_FILE = "/data/devices.toml";
      };
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      raw.volumes = ["${devicesFile}:/data/devices.toml:ro"];
    };
  };
}
