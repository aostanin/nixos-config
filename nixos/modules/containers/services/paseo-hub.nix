{
  lib,
  config,
  ...
}: let
  name = "paseo-hub";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/getpaseo/hub:latest";
      raw.environment = {
        PASEO_HUB_APP_URL = "https://${lib.head (config.lib.containers.mkHosts name)}";
        PASEO_HUB_DATA_DIR = "/data";
        PASEO_HUB_TRUSTED_CLIENT_IP_HEADER = "x-forwarded-for";
      };
      volumes.data.destination = "/data";
      healthcheck = {
        cmd = "node -e \"fetch('http://localhost:3000/health').then(r=>{if(!r.ok)process.exit(1)}).catch(()=>process.exit(1))\"";
        startPeriod = "30s";
      };
      proxy = {
        enable = true;
        port = 3000;
      };
    };

    # An unclean shutdown leaves these behind and the hub then refuses to start;
    # nothing can hold them while the unit is starting.
    systemd.services."podman-${name}".preStart = let
      data = config.localModules.containers.containers.${name}.volumes.data.source;
    in ''
      rm -f ${lib.escapeShellArg "${data}/.paseo-hub.lock"} ${lib.escapeShellArg "${data}/postmaster.pid"}
    '';
  };
}
