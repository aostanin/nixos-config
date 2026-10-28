{
  config,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./backup.nix
    ./home-assistant.nix
    ./kernel.nix
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

    traefik.enable = true;
  };

  # TODO: Change default gateway based on if Starlink is actually connected
}
