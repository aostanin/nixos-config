{
  lib,
  config,
  secrets,
  ...
}: let
  cfg = config.localModules.networkmanager;
in {
  options.localModules.networkmanager = {
    enable = lib.mkEnableOption "NetworkManager";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."networkmanager/wifi_psks" = {};

    networking = {
      hostName = "skye";
      hostId = "e9fbbf71";
      networkmanager = {
        enable = true;
        ensureProfiles = {
          profiles = secrets.networkmanager.profiles;
          environmentFiles = [config.sops.secrets."networkmanager/wifi_psks".path];
        };
      };
    };
  };
}
