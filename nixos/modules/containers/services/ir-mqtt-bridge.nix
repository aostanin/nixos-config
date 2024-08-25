{
  lib,
  config,
  secrets,
  containerLib,
  ...
}:
with containerLib; let
  name = "ir-mqtt-bridge";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
  };

  config = lib.mkIf (config.localModules.containers.enable && cfg.enable) {
    localModules.containers.services.${name} = {
      autoupdate = lib.mkDefault true;
    };

    sops.secrets."forgejo/registry_token" = {};

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "${secrets.forgejo.registry}/${secrets.forgejo.username}/ir-mqtt";
        login = {
          inherit (secrets.forgejo) registry username;
          passwordFile = config.sops.secrets."forgejo/registry_token".path;
        };
      }
      mkContainerDefaultConfig
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];
  };
}
