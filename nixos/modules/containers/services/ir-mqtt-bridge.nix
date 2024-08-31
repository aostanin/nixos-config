{
  lib,
  config,
  secrets,
  ...
}: let
  name = "ir-mqtt-bridge";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."forgejo/registry_token" = {};

    localModules.containers.containers.${name} = {
      raw.image = "${secrets.forgejo.registry}/${secrets.forgejo.username}/ir-mqtt:latest";
      raw.login = {
        inherit (secrets.forgejo) registry username;
        passwordFile = config.sops.secrets."forgejo/registry_token".path;
      };
    };
  };
}
