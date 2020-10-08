{ config, pkgs, ... }:

{
  imports = [
    <nixos-hardware/lenovo/thinkpad/t440p>
    <nixos-hardware/common/pc/laptop/ssd>
    ./hardware-configuration.nix
    ../../modules/variables
    ../../modules/common
    ../../modules/desktop
    ../../modules/syncthing
    ../../modules/zerotier
    ../../home
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
    kernelModules = [
      "v4l2loopback"
    ];
    extraModulePackages = with config.boot.kernelPackages; [
      exfat-nofuse
      v4l2loopback
    ];
    extraModprobeConfig = ''
      options v4l2loopback video_nr=10 card_label="OBS Studio" exclusive_caps=1
    '';

    kernelParams = [
      "zfs.zfs_arc_max=2147483648"
      "acpi_osi=\"!Windows 2013\"" # Needed to disable NVIDIA card
      "acpi_osi=Linux"
    ];
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
        USB_AUTOSUSPEND=0
        START_CHARGE_THRESH_BAT0=75
        STOP_CHARGE_THRESH_BAT0=80
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
      displayManager.sessionCommands = ''
        xinput set-prop "TPPS/2 IBM TrackPoint" "libinput Natural Scrolling Enabled" 0
      '';
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

  hardware = {
    nvidiaOptimus.disable = true;

    pulseaudio.extraConfig = ''
      load-module module-simple-protocol-tcp source=alsa_output.pci-0000_00_1b.0.analog-stereo.monitor record=true
    '';
  };

  programs.adb.enable = true;

  virtualisation = {
    libvirtd.enable = true;

    docker = {
      enable = true;
      storageDriver = "zfs";
    };
  };
}
