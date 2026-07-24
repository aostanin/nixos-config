{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: {
  localModules = {
    common.enable = true;

    desktop.enable = true;

    gnupg.enable = true;

    sway = {
      useNetworkManager = true;
      primaryOutput = "eDP-1";
      wallpaper = "${inputs.nixos-artwork}/wallpapers/nix-wallpaper-nineish-dark-gray.png";
    };
  };
}
