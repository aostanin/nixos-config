{
  config,
  pkgs,
  secrets,
  ...
}: {
  sops.secrets = {
    "${config.networking.hostName}/wlan/password" = {};
  };

  environment.systemPackages = with pkgs; [
    iw
  ];

  services.hostapd = {
    enable = true;
    radios = {
      wlan0 = {
        countryCode = "JP";
        band = "2g";
        networks.wlan0 = {
          ssid = secrets."${config.networking.hostName}".wlan.ssid;
          authentication = {
            mode = "wpa3-sae-transition";
            saePasswords = [{passwordFile = config.sops.secrets."${config.networking.hostName}/wlan/password".path;}];
            wpaPasswordFile = config.sops.secrets."${config.networking.hostName}/wlan/password".path;
          };
        };
      };

      wlan1 = {
        countryCode = "JP";
        band = "5g";
        networks.wlan1 = {
          ssid = secrets."${config.networking.hostName}".wlan.ssid;
          authentication = {
            mode = "wpa3-sae-transition";
            saePasswords = [{passwordFile = config.sops.secrets."${config.networking.hostName}/wlan/password".path;}];
            wpaPasswordFile = config.sops.secrets."${config.networking.hostName}/wlan/password".path;
          };
        };
      };
    };
  };
}
