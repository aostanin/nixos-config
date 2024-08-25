{
  lib,
  config,
  secrets,
  containerLib,
  ...
}:
with containerLib; let
  name = "jobcan";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption name {};
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
      "forgejo/registry_token" = {};
      "containers/jobcan/api_token" = {};
      "containers/jobcan/jobcan_username" = {};
      "containers/jobcan/jobcan_password" = {};
      "containers/jobcan/slack_token" = {};
      "containers/jobcan/slack_channel" = {};
    };

    sops.templates."${name}.env".content = ''
      API_TOKEN=${config.sops.placeholder."containers/jobcan/api_token"}
      JOBCAN_USERNAME=${config.sops.placeholder."containers/jobcan/jobcan_username"}
      JOBCAN_PASSWORD=${config.sops.placeholder."containers/jobcan/jobcan_password"}
      SLACK_TOKEN=${config.sops.placeholder."containers/jobcan/slack_token"}
      SLACK_CHANNEL=${config.sops.placeholder."containers/jobcan/slack_channel"}
    '';

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "${secrets.forgejo.registry}/${secrets.forgejo.username}/jobcan";
        login = {
          inherit (secrets.forgejo) registry username;
          passwordFile = config.sops.secrets."forgejo/registry_token".path;
        };
        environment = {
          RUST_LOG = "debug";
        };
        environmentFiles = [config.sops.templates."${name}.env".path];
      }
      mkContainerDefaultConfig
      (mkContainerProxyConfig name cfg.proxy)
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.services."podman-${name}" = mkServiceProxyConfig name cfg.proxy;
  };
}
