{
  config,
  pkgs,
  hardwareModulesPath,
  secrets,
  ...
}: {
  imports = [
    "${hardwareModulesPath}/common/cpu/amd"
    "${hardwareModulesPath}/common/cpu/amd/pstate.nix"
    "${hardwareModulesPath}/common/gpu/amd"
    "${hardwareModulesPath}/common/pc/laptop"
    "${hardwareModulesPath}/common/pc/laptop/acpi_call.nix"
    "${hardwareModulesPath}/common/pc/laptop/ssd"
    ./hardware-configuration.nix
    ../../modules
    ../../modules/common
    ../../modules/msmtp
    ../../modules/zerotier
    ./backup.nix
  ];

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = ["zfs"];
    tmp.useTmpfs = true;
    kernelParams = [
      "amd_iommu=on"
      "iommu=pt"
      "zfs.zfs_arc_max=2147483648"
    ];
    binfmt.emulatedSystems = ["aarch64-linux"];
  };

  networking = {
    hostName = "skye";
    hostId = "e9fbbf71";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
      ];
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        } # KDE Connect
      ];
      allowedUDPPorts = [
        5353 # Avahi
        9993 # ZeroTier
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        } # KDE Connect
      ];
      interfaces."${secrets.zerotier.interface}" = {
        allowedTCPPorts = [
          22000 # Syncthing
        ];
        allowedUDPPorts = [
          22000 # Syncthing
          21027 # Syncthing
        ];
      };
    };
  };

  powerManagement.powertop.enable = true;

  localModules = {
    desktop = {
      enable = true;
      hasBattery = true;
      hasBacklightControl = true;
      primaryOutput = "eDP-1";
      output = {
        "*" = {
          bg = "~/Sync/wallpaper/nix-wallpaper-nineish-dark-gray.png fill";
        };
      };
    };

    rkvm.client = {
      enable = true;
      server = "${secrets.network.home.hosts.valmar.address}:5258";
      certificate = secrets.rkvm.certificate;
      password = secrets.rkvm.password;
    };
  };

  services = {
    logind.lidSwitchDocked = "suspend";

    tlp = {
      enable = true;
      settings = {
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };

    xserver.videoDrivers = ["modesetting"];

    zfs = {
      autoScrub = {
        enable = true;
        interval = "monthly";
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
  };

  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "zfs";
      liveRestore = false;
      autoPrune = {
        enable = true;
        flags = [
          "--all"
          "--filter \"until=168h\""
        ];
      };
    };

    libvirtd.enable = true;

    waydroid.enable = true;
  };
}