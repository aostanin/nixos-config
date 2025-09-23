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
      networkmanager = {
        enable = true;
        wifi.backend = "iwd";
        ensureProfiles = {
          profiles = secrets.networkmanager.profiles;
          environmentFiles = [config.sops.secrets."networkmanager/wifi_psks".path];
        };
      };

      wireless.iwd.settings.General.Country = "JP";
    };
  };
}
