{
  lib,
  config,
  ...
}: let
  name = "grafana";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "containers/grafana/smtp_host" = {};
      "containers/grafana/smtp_user" = {};
      "containers/grafana/smtp_password" = {};
      "containers/grafana/smtp_from_address" = {};
    };

    sops.templates."${name}.env".content = ''
      GF_SMTP_HOST=${config.sops.placeholder."containers/grafana/smtp_host"}
      GF_SMTP_USER=${config.sops.placeholder."containers/grafana/smtp_user"}
      GF_SMTP_PASSWORD=${config.sops.placeholder."containers/grafana/smtp_password"}
      GF_SMTP_FROM_ADDRESS=${config.sops.placeholder."containers/grafana/smtp_from_address"}
    '';

    localModules.containers.containers.${name} = {
      raw.image = "docker.io/grafana/grafana-oss:latest";
      raw.environment = {
        GF_SERVER_ROOT_URL = "https://${lib.head (config.lib.containers.mkHosts name)}";
        GF_SMTP_ENABLED = "true";
      };
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      volumes.data = {
        destination = "/var/lib/grafana";
        user = "472";
      };
      proxy = {
        enable = true;
        port = 3000;
      };
    };
  };
}
