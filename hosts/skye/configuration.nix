{
  config,
  pkgs,
  lib,
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
      workspaceOutputAssign = builtins.map (x: {
        workspace = builtins.toString x;
        output =
          if (lib.mod x 3) == 1
          then [secrets.monitors.lg.name "eDP-1"]
          else if (lib.mod x 3) == 2
          then [secrets.monitors.dell.name "eDP-1"]
          else "eDP-1";
      }) [1 2 3 4 5 6 7 8 9];
    };

    docker = {
      enable = true;
      enableAutoPrune = true;
    };

    zfs.enable = true;
  };

  # Mic LED is always on. Turn it off.
  systemd.services.disable-mic-led = {
    wantedBy = ["graphical.target"];
    partOf = ["graphical.target"];
    after = ["graphical.target"];
    serviceConfig.Type = "oneshot";
    script = "echo 0 > /sys/class/leds/platform::micmute/brightness";
  };

  services = {
    fprintd = {
      enable = true;
      tod = {
        enable = true;
        driver = pkgs.libfprint-2-tod1-goodix;
      };
    };

    logind.extraConfig = ''
      HandlePowerKey=suspend
    '';

    tlp = {
      enable = true;
      settings = {
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        USB_DENYLIST = "04d9:4545"; # Keyboard
      };
    };

    xserver.videoDrivers = ["amdgpu"];
  };

  virtualisation = {
    libvirtd.enable = true;

    waydroid.enable = true;
  };
}
