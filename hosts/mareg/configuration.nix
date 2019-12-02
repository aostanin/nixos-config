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
    ../../modules/mullvad-vpn
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

    kernelParams = [
      "zfs.zfs_arc_max=2147483648"
    ];
    kernelPatches = [ {
      # Fix Magic Mouse / Trackpad disconnects
      # ref: https://bugzilla.kernel.org/show_bug.cgi?id=103631
      name = "disable-hid-battery-strength";
      patch = null;
      extraConfig = ''
        HID_BATTERY_STRENGTH n
      '';
    } ];
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
    '';
  };

  programs.adb.enable = true;

  virtualisation.libvirtd.enable = true;
}
