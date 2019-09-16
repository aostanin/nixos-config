{ config, pkgs, ... }:

let
  #nixos-hardware = builtins.fetchTarball {
  #  url = "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
  #};
in {
  imports = [
    #"${nixos-hardware}/apple/macbook-pro/12-1"
    ./hardware-configuration.nix
    ../../modules/common
    ../../modules/desktop
    ../../modules/syncthing
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "millenia";
    hostId = "6556bbae";
    networkmanager.enable = true;
  };

  services.flatpak.enable = true;

  services.xserver = {
    #xkbOptions = "ctrl:nocaps, shift:both_capslock";
    libinput = {
      enable = true;
      clickMethod = "clickfinger";
      naturalScrolling = true;
    };
  };

  virtualisation.libvirtd.enable = true;
}
