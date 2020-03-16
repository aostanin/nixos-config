{ config, pkgs, ... }:

{
  imports = [
    <nixos-hardware/lenovo/thinkpad/x250>
    <nixos-hardware/common/pc/laptop/ssd>
    ./hardware-configuration.nix
    ../../modules/common
    ../../modules/desktop
    ../../modules/mullvad-vpn
    ../../modules/syncthing
    ../../modules/zerotier
    ../../home
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

  services = {
    tlp = {
      enable = true;
      extraConfig = ''
        USB_AUTOSUSPEND=0
        START_CHARGE_THRESH_BAT0=75
        STOP_CHARGE_THRESH_BAT0=80
        START_CHARGE_THRESH_BAT1=75
        STOP_CHARGE_THRESH_BAT1=80
      '';
    };

    xserver = {
      videoDrivers = [ "intel" ];
      deviceSection = ''
        Option "TearFree" "true"
      '';
      xkbOptions = "ctrl:nocaps, shift:both_capslock";
      libinput = {
        enable = true;
        clickMethod = "clickfinger";
        naturalScrolling = true;
        tapping = false;
      };
    };

    zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };

    znapzend = {
      enable = true;
      pure = true;
      autoCreation = true;
      zetup = {
        "rpool/home" = {
          plan = "1day=>1hour,1week=>1day,1month=>1week";
          destinations.remote = {
            host = "elena";
            dataset = "tank/backup/hosts/${config.networking.hostName}/home";
            plan = "1week=>1day,1month=>1week,3month=>1month";
          };
        };
        "rpool/root/nixos" = {
          recursive = true;
          plan = "1day=>1hour,1week=>1day,1month=>1week";
          destinations.remote = {
            host = "elena";
            dataset = "tank/backup/hosts/${config.networking.hostName}/root/nixos";
            plan = "1week=>1day,1month=>1week,3month=>1month";
          };
        };
      };
    };
  };

  virtualisation = {
    libvirtd.enable = true;
    docker = {
      enable = true;
      storageDriver = "zfs";
    };
  };
}
