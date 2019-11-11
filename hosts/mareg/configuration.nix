{ config, pkgs, ... }:

let
  nixos-hardware = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
  };
in {
  imports = [
    "${nixos-hardware}/lenovo/thinkpad/t440p"
    "${nixos-hardware}/common/pc/laptop/ssd"
    ./hardware-configuration.nix
    ../../modules/common
    ../../modules/desktop
    ../../modules/syncthing
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = [ "zfs" ];
    blacklistedKernelModules = [ "nouveau" ];
    extraModulePackages = [ config.boot.kernelPackages.exfat-nofuse ];
    extraModprobeConfig = ''
      options hid_apple fnmode=2
    '';
  };

  networking = {
    hostName = "mareg";
    hostId = "393740af";
    networkmanager.enable = true;
  };

  services.zfs = {
    autoScrub.enable = true;
    autoSnapshot = {
      enable = true;
      monthly = 1;
    };
    trim.enable = true;
  };

  services.flatpak.enable = true;

  services.xserver = {
    xkbOptions = "ctrl:nocaps, shift:both_capslock";
    libinput = {
      enable = true;
      clickMethod = "clickfinger";
      naturalScrolling = true;
    };
  };

  services.tlp = {
    enable = true;
    extraConfig = ''
      START_CHARGE_THRESH_BAT0=70
      STOP_CHARGE_THRESH_BAT0=80
    '';
  };

  programs.adb.enable = true;

  virtualisation.libvirtd.enable = true;

  boot.kernelModules = [ "vfio_pci" ];
  boot.kernelParams = [
    "intel_iommu=on"
  ];
}
