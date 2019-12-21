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
    ../../home
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = [ "zfs" ];
    extraModulePackages = [ config.boot.kernelPackages.exfat-nofuse ];
    extraModprobeConfig = ''
      options hid_apple fnmode=2
    '';

    kernelParams = [
      "zfs.zfs_arc_max=2147483648"
      "acpi_osi=\"!Windows 2013\"" # Needed to disable NVIDIA card
      "acpi_osi=Linux"
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

  services = {
    tlp = {
      enable = true;
      extraConfig = ''
        START_CHARGE_THRESH_BAT0=75
        STOP_CHARGE_THRESH_BAT0=80
      '';
    };

    xserver = {
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

  hardware.nvidiaOptimus.disable = true;

  programs.adb.enable = true;

  virtualisation = {
    libvirtd.enable = true;

    docker = {
      enable = true;
      storageDriver = "zfs";
    };
  };
}
