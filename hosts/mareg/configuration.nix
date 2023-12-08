{
  config,
  pkgs,
  hardwareModulesPath,
  secrets,
  ...
}: {
  imports = [
    "${hardwareModulesPath}/lenovo/thinkpad/t440p"
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
    tmp.useTmpfs = true;
    kernelParams = [
      "intel_iommu=on"
      "iommu=pt"
      "intel_pstate=active"
      "i915.enable_fbc=1"
      "zfs.zfs_arc_max=2147483648"
      "acpi_osi=\"!Windows 2013\"" # Needed to disable NVIDIA card
      "acpi_osi=Linux"
    ];
    binfmt.emulatedSystems = ["aarch64-linux"];
  };

  networking = {
    hostName = "mareg";
    hostId = "393740af";
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
          bg = "~/Sync/wallpaper/t440p.png fill";
        };
      };
    };

    docker = {
      enable = true;
      enableAutoPrune = true;
    };

    rkvm.client = {
      enable = true;
      server = "${secrets.network.home.hosts.valmar.address}:5258";
      certificate = secrets.rkvm.certificate;
      password = secrets.rkvm.password;
    };

    zfs.enable = true;
  };

  services = {
    logind.lidSwitchDocked = "suspend";

    tlp = {
      enable = true;
      settings = {
        USB_AUTOSUSPEND = 0;
        START_CHARGE_THRESH_BAT0 = 85;
        STOP_CHARGE_THRESH_BAT0 = 90;
      };
    };

    xserver.videoDrivers = ["modesetting"];
  };

  hardware = {
    nvidiaOptimus.disable = true;
  };

  virtualisation = {
    libvirtd.enable = true;

    waydroid.enable = true;
  };
}
