{
  lib,
  config,
  ...
}: let
  name = "navidrome";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    volumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra volumes to bind to the container.";
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/deluan/navidrome:latest";
      raw.environment = {
        # 1 am in UTC
        ND_SCANSCHEDULE = "0 16 * * *";
        ND_AUTOIMPORTPLAYLISTS = "false";
      };
      volumes.data.destination = "/data";
      raw.volumes = cfg.volumes;
      healthcheck = {
        cmd = "wget -qO- http://localhost:4533/ping";
        startPeriod = "30s";
      };
      proxy = {
        enable = true;
        port = 4533;
      };
    };
  };
}
