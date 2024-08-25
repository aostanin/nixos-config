{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "grafana";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption name {port = 3000;};
    volumes = mkVolumesOption name {
      data = {user = "472";};
    };
  };

  config = lib.mkIf (config.localModules.containers.enable && cfg.enable) {
    localModules.containers.services.${name} = {
      autoupdate = lib.mkDefault true;
      proxy = {
        enable = lib.mkDefault true;
        tailscale.enable = lib.mkDefault true;
      };
    };

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

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "docker.io/grafana/grafana-oss:latest";
        environment = {
          GF_SERVER_ROOT_URL = "https://${lib.head cfg.proxy.hosts}";
          GF_SMTP_ENABLED = "true";
        };
        environmentFiles = [config.sops.templates."${name}.env".path];
        volumes = [
          "${cfg.volumes.data.path}:/var/lib/grafana"
        ];
      }
      mkContainerDefaultConfig
      (mkContainerProxyConfig name cfg.proxy)
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.services."podman-${name}" = mkServiceProxyConfig name cfg.proxy;

    systemd.tmpfiles.rules = mkTmpfileVolumesConfig cfg.volumes;
  };
}
