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
    ./wwan
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
    kernelPackages = pkgs.linuxPackages_6_6;
    kernelParams = [
      "amd_iommu=on"
      "iommu=pt"
      "pcie_aspm.policy=powersave"
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

    docker = {
      enable = true;
      enableAutoPrune = true;
    };

    zfs.enable = true;
  };

  services = {
    tlp = {
      enable = true;
      settings = {
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      };
    };

    xserver.videoDrivers = ["amdgpu"];
  };

  virtualisation = {
    libvirtd.enable = true;

    waydroid.enable = true;
  };
}
