{
  lib,
  config,
  ...
}: let
  name = "grist";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."containers/${name}/session_secret" = {};

    sops.templates."${name}.env".content = ''
      GRIST_SESSION_SECRET=${config.sops.placeholder."containers/${name}/session_secret"}
    '';

    localModules.containers.containers.${name} = {
      raw.image = "docker.io/gristlabs/grist:latest";
      raw.environment = {
        GRIST_DEFAULT_EMAIL = "aostanin@${config.localModules.containers.domain}";
        GRIST_SERVE_SAME_ORIGIN = "true";
      };
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      volumes.persist = {
        destination = "/persist";
        user = "1001";
        group = "1001";
      };
      healthcheck = {
        cmd = "curl -f http://localhost:8484/status";
        startPeriod = "30s";
      };
      proxy = {
        enable = true;
        port = 8484;
      };
    };
  };
}
