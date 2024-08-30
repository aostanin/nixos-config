{
  lib,
  config,
  secrets,
  ...
}: let
  name = "jobcan";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
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

    localModules.containers.containers.${name} = {
      raw.image = "${secrets.forgejo.registry}/${secrets.forgejo.username}/jobcan";
      raw.login = {
        inherit (secrets.forgejo) registry username;
        passwordFile = config.sops.secrets."forgejo/registry_token".path;
      };
      raw.environment = {
        RUST_LOG = "debug";
      };
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      proxy.enable = true;
    };
  };
}
