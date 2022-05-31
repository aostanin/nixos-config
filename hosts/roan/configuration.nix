{ config, pkgs, hardwareModulesPath, ... }:
let
  secrets = import ../../secrets;
in
{
  imports = [
    "${hardwareModulesPath}/lenovo/thinkpad/x250"
    "${hardwareModulesPath}/common/pc/laptop/ssd"
    ./hardware-configuration.nix
    ../../modules/variables
    ../../modules/common
    ../../modules/desktop
    ../../modules/msmtp
    ../../modules/zerotier
  ];

  variables = {
    hasBattery = true;
    hasBacklightControl = true;
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = [ "zfs" ];
    kernelParams = [
      "zfs.zfs_arc_max=2147483648"
    ];
  };

  networking = {
    hostName = "roan";
    hostId = "9bc52069";
    networkmanager.enable = true;
  };

  powerManagement.powertop.enable = true;

  services = {
    tlp = {
      enable = true;
      settings = {
        USB_AUTOSUSPEND = 0;
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;
        START_CHARGE_THRESH_BAT1 = 75;
        STOP_CHARGE_THRESH_BAT1 = 80;
      };
    };

    undervolt = {
      enable = true;
      coreOffset = -40;
      gpuOffset = -30;
    };

    xserver = {
      videoDrivers = [ "intel" ];
      deviceSection = ''
        Option "TearFree" "true"
      '';
      xkbOptions = "ctrl:nocaps, shift:both_capslock";
      libinput = {
        enable = true;
        touchpad = {
          clickMethod = "clickfinger";
          naturalScrolling = true;
          tapping = false;
        };
      };
    };

    zfs = {
      autoScrub = {
        enable = true;
        interval = "monthly";
      };
      autoSnapshot = {
        enable = true;
        monthly = 0;
      };
      trim.enable = true;
      zed = {
        enableMail = true;
        settings = {
          ZED_EMAIL_ADDR = secrets.user.emailAddress;
          ZED_NOTIFY_VERBOSE = true;
        };
      };
    };

    znapzend = {
      enable = true;
      pure = true;
      autoCreation = true;
      features = {
        compressed = true;
        recvu = true;
        zfsGetType = true;
      };
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

  programs.adb.enable = true;

  virtualisation = {
    libvirtd.enable = true;
    docker = {
      enable = true;
      storageDriver = "zfs";
      autoPrune = {
        enable = true;
        flags = [
          "--all"
          "--filter \"until=168h\""
        ];
      };
    };
  };
}
