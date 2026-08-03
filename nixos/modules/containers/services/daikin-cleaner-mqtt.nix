{
  lib,
  config,
  secrets,
  ...
}: let
  name = "daikin-cleaner-mqtt";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."forgejo/registry_token" = {};

    localModules.containers.containers.${name} = {
      raw.image = "${secrets.forgejo.registry}/${secrets.forgejo.username}/${name}:latest";
      raw.login = {
        inherit (secrets.forgejo) registry username;
        passwordFile = config.sops.secrets."forgejo/registry_token".path;
      };
      raw.environment = {
        RUST_LOG = "debug";
        MQTT_HOST = secrets.mqtt.host;
        DEVICE_HOST = secrets.daikinCleanerMqtt.deviceHost;
      };
    };
  };
}
