{
  lib,
  pkgs,
  config,
  secrets,
  ...
}: let
  name = "valetudopng";
  cfg = config.localModules.containers.services.${name};
  settings = {
    mqtt = {
      connection = {
        host = secrets.mqtt.host;
        port = 1883;
        client_id_prefix = "valetudopng";
        tls_enabled = false;
      };
      topics = {
        valetudo_prefix = "valetudo";
        valetudo_identifier = "robot";
        ha_autoconf_prefix = "homeassistant";
      };
      image_as_base64 = false;
    };
    http = {
      enabled = true;
      bind = "0.0.0.0:3000";
    };
    map = {
      min_refresh_int = "5000ms";
      png_compression = 0;
      scale = 4;
      rotate = 0;
      colors = {
        floor = "#0076ff";
        obstacle = "#5d5d5d";
        path = "#ffffff";
        no_go_area = "#ff00004a";
        virtual_wall = "#ff0000bf";
        segments = ["#19a1a1" "#7ac037" "#ff9b57" "#f7c841"];
      };
    };
  };
  configFile = pkgs.writeText "${name}-config.yml" (lib.generators.toYAML {} settings);
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/erkexzcx/valetudopng:latest";
      raw.volumes = ["${configFile}:/config/config.yml:ro"];
      raw.cmd = ["-config" "/config/config.yml"];
      proxy = {
        enable = true;
        port = 3000;
      };
    };
  };
}
