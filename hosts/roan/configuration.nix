{ config, pkgs, ... }:

let
  nixos-hardware = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
  };
in {
  imports = [
    "${nixos-hardware}/lenovo/thinkpad/x250"
    "${nixos-hardware}/common/pc/laptop/ssd"
    ./hardware-configuration.nix
    ../../modules/common
    ../../modules/desktop
    ../../modules/mullvad-vpn
    ../../modules/syncthing
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = [ "zfs" ];
    extraModulePackages = [ config.boot.kernelPackages.exfat-nofuse ];
    kernelParams = [
      "zfs.zfs_arc_max=2147483648"
    ];
  };

  networking = {
    hostName = "roan";
    hostId = "9bc52069";
    networkmanager.enable = true;
  };

  services.zfs = {
    autoScrub.enable = true;
    autoSnapshot = {
      enable = true;
      weekly = 0;
      monthly = 0;
    };
    trim.enable = true;
  };

  services.xserver = {
    xkbOptions = "ctrl:nocaps, shift:both_capslock";
    libinput = {
      enable = true;
      clickMethod = "clickfinger";
      naturalScrolling = true;
      tapping = false;
    };
  };

  services.tlp = {
    enable = true;
    extraConfig = ''
      START_CHARGE_THRESH_BAT0=70
      STOP_CHARGE_THRESH_BAT0=80
      START_CHARGE_THRESH_BAT1=70
      STOP_CHARGE_THRESH_BAT1=80
    '';
  };

  services.undervolt = {
    enable = true;
    coreOffset = "-70";
  };

  virtualisation.libvirtd.enable = true;
}
