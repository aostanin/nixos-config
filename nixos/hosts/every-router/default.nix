{...}: {
  imports = [
    ./hardware-configuration.nix
    ./home-assistant.nix
    ./network.nix
    ./router.nix
    ./power-management.nix
    ./wlan.nix
    ./wwan.nix
  ];

  networking.hostName = "every-router";

  localModules = {
    common = {
      enable = true;
      minimal = true;
    };
  };
}
