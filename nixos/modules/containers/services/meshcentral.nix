{
  lib,
  config,
  ...
}: let
  name = "meshcentral";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/typhonragewind/meshcentral:latest";
      raw.environment = {
        HOSTNAME = lib.head (config.lib.containers.mkHosts name);
        REVERSE_PROXY = "false";
        REVERSE_PROXY_TLS_PORT = "443";
        IFRAME = "false";
        ALLOW_NEW_ACCOUNTS = "false";
        WEBRTC = "true";
        NODE_ENV = "production";
      };
      volumes = {
        data.destination = "/opt/meshcentral/meshcentral-data";
        files.destination = "/opt/meshcentral/meshcentral-files";
        backup.destination = "/opt/meshcentral/meshcentral-backup";
      };
      proxy = {
        enable = true;
        port = 443;
        scheme = "https";
      };
    };
  };
}
