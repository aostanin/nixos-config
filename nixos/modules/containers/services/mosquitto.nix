{
  lib,
  pkgs,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "mosquitto";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    volumes = mkVolumesOption name {
      data = {};
    };
  };

  config = lib.mkIf (config.localModules.containers.enable && cfg.enable) {
    localModules.containers.services.${name} = {
      # Prevent all clients from disconnecting
      autoupdate = lib.mkDefault false;
    };

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "docker.io/library/eclipse-mosquitto:latest";
        ports = ["1883:1883"];
        volumes = let
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
        in [
          "${configFile}:/mosquitto/config/mosquitto.conf"
          "${cfg.volumes.data.path}:/mosquitto/data"
        ];
      }
      mkContainerDefaultConfig
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.tmpfiles.rules = mkTmpfileVolumesConfig cfg.volumes;
  };
}
