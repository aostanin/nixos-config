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
      "containers/jobcan/moneyforward_username" = {};
      "containers/jobcan/moneyforward_password" = {};
      "containers/jobcan/slack_token" = {};
      "containers/jobcan/slack_channel" = {};
    };

    sops.templates."${name}.env".content = ''
      API_TOKEN=${config.sops.placeholder."containers/jobcan/api_token"}
      MODE=moneyforward
      MONEYFORWARD_USERNAME=${config.sops.placeholder."containers/jobcan/moneyforward_username"}
      MONEYFORWARD_PASSWORD=${config.sops.placeholder."containers/jobcan/moneyforward_password"}
      SLACK_TOKEN=${config.sops.placeholder."containers/jobcan/slack_token"}
      SLACK_CHANNEL=${config.sops.placeholder."containers/jobcan/slack_channel"}
    '';

    localModules.containers.containers.${name} = {
      raw.image = "${secrets.forgejo.registry}/${secrets.forgejo.username}/jobcan:latest";
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
