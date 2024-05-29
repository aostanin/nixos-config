{
  config,
  pkgs,
  lib,
  inputs,
  secrets,
  ...
}: {
  imports = [
    "${inputs.nixos-hardware}/common/cpu/amd"
    "${inputs.nixos-hardware}/common/cpu/amd/pstate.nix"
    "${inputs.nixos-hardware}/common/gpu/amd"
    "${inputs.nixos-hardware}/common/pc/laptop"
    "${inputs.nixos-hardware}/common/pc/laptop/acpi_call.nix"
    "${inputs.nixos-hardware}/common/pc/laptop/ssd"
    ./hardware-configuration.nix
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
    ];
    binfmt.emulatedSystems = ["aarch64-linux"];
  };

  networking = {
    hostName = "skye";
    hostId = "e9fbbf71";
    networkmanager = {
      enable = true;
      ensureProfiles.profiles = secrets.networkmanager.profiles;
    };
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

  time.timeZone = "US/Pacific";

  localModules = {
    common.enable = true;

    desktop = {
      enable = true;
      enableGaming = true;
    };

    docker = {
      enable = true;
      enableAutoPrune = true;
    };

    zfs = {
      enable = true;
      allowHibernation = true;
    };
  };

  # Mic LED is always on. Turn it off.
  systemd.services.disable-mic-led = {
    wantedBy = ["graphical.target"];
    partOf = ["graphical.target"];
    after = ["graphical.target"];
    serviceConfig.Type = "oneshot";
    script = "echo 0 > /sys/class/leds/platform::micmute/brightness";
  };

  services.udev.extraRules = ''
    # Disable wakeup from sleep on touchpad activity
    KERNEL=="i2c-SYNA88024:00", SUBSYSTEM=="i2c", ATTR{power/wakeup}="disabled"
  '';

  services = {
    fprintd = {
      enable = true;
      tod = {
        enable = true;
        driver = pkgs.libfprint-2-tod1-goodix;
      };
    };

    logind = {
      lidSwitchDocked = "suspend";
      extraConfig = ''
        HandlePowerKey=suspend
      '';
    };

    ollama.enable = true;

    tlp = {
      enable = true;
      settings = {
        # Battery
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;

        # CPU
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        # PCIe
        RUNTIME_PM_ON_AC = "auto";
        RUNTIME_PM_ON_BAT = "auto";
        PCIE_ASPM_ON_AC = "powersave";
        PCIE_ASPM_ON_BAT = "powersave";

        # USB
        USB_EXCLUDE_AUDIO = 0;
        USB_EXCLUDE_PRINTER = 0;
        USB_DENYLIST = "04d9:4545"; # Keyboard

        # Wi-Fi
        WIFI_PWR_ON_BAT = "off"; # Wi-Fi is unstable in power-saving mode
      };
    };

    xserver.videoDrivers = ["amdgpu"];
  };

  virtualisation = {
    # TODO: Create localModule
    libvirtd = {
      enable = true;
      qemu.ovmf.packages = [pkgs.OVMFFull.fd];
      qemu.swtpm.enable = true;
    };

    waydroid.enable = true;
  };
}
