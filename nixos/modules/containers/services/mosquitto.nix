{
  lib,
  pkgs,
  config,
  ...
}: let
  name = "mosquitto";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/library/eclipse-mosquitto:latest";
      # Prevent all clients from disconnecting
      autoupdate = false;
      raw.ports = ["1883:1883"];
      volumes.data.destination = "/mosquitto/data";
      raw.volumes = let
        configFile = pkgs.writeTextFile {
          name = "mosquitto.conf";
          text = ''
            persistence true
            persistence_location /mosquitto/data/
            log_dest stdout
            listener 1883
            allow_anonymous true
          '';
        };
      in ["${configFile}:/mosquitto/config/mosquitto.conf"];
    };
  };
}
