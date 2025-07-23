{
  config,
  pkgs,
  lib,
  inputs,
  secrets,
  ...
}: {
  imports = [
    "${inputs.nixos-hardware}/lenovo/thinkpad/t14/amd/gen4"
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
    kernelPackages = pkgs.linuxPackages_6_12;
    kernelParams = [
      "amd_iommu=on"
      "iommu=pt"
      "zfs.zfs_arc_max=8589934592"
    ];
    binfmt.emulatedSystems = ["aarch64-linux"];
  };

  networking = {
    hostName = "skye";
    hostId = "e9fbbf71";
    firewall = {
      enable = true;
      interfaces.tailscale0 = {
        allowedTCPPorts = [
          22 # SSH
          80 # HTTP
          443 # HTTPS
          22000 # Syncthing
        ];
        allowedTCPPortRanges = [
          {
            from = 1714;
            to = 1764;
          } # KDE Connect
        ];
        allowedUDPPorts = [
          5353 # Avahi
          22000 # Syncthing
          21027 # Syncthing
        ];
        allowedUDPPortRanges = [
          {
            from = 1714;
            to = 1764;
          } # KDE Connect
        ];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    linux-wifi-hotspot
  ];

  localModules = {
    backup = {
      enable = true;
      paths = [
        "/home"
        # "/storage/appdata"
        "/var/lib/libvirt"
        "/var/lib/nixos"
        "/var/lib/tailscale"
        "/var/lib/traefik"
      ];
      exclude = [
        "/home/*/.local/share/containers"
        "/home/*/.local/share/Steam/steamapps"
      ];
    };

    common.enable = true;

    desktop = {
      enable = true;
      enableGaming = true;
    };

    networkmanager.enable = true;

    nvtop.package = pkgs.nvtopPackages.amd;

    podman = {
      enable = true;
      enableAutoPrune = true;
    };

    tailscale = {
      isClient = true;
      extraFlags = [
        "--accept-routes"
        "--operator=${secrets.user.username}"
      ];
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

    fwupd.enable = true;

    logind = {
      lidSwitch = "suspend";
      lidSwitchDocked = config.services.logind.lidSwitch;
      powerKey = config.services.logind.lidSwitch;
    };

    ollama.enable = true;

    tlp = {
      enable = true;
      settings = {
        # Battery
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;

        # CPU
        CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;

        # Graphics
        RADEON_DPM_PERF_LEVEL_ON_AC = "auto";
        RADEON_DPM_PERF_LEVEL_ON_BAT = "low";

        # PCIe
        RUNTIME_PM_ON_AC = "auto";
        RUNTIME_PM_ON_BAT = "auto";
        PCIE_ASPM_ON_AC = "powersave";
        PCIE_ASPM_ON_BAT = "powersupersave";

        # Platform
        PLATFORM_PROFILE_ON_AC = "balanced";
        PLATFORM_PROFILE_ON_BAT = "low-power";

        # Radio Devices
        DEVICES_TO_DISABLE_ON_STARTUP = "nfc";

        # USB
        USB_EXCLUDE_AUDIO = 0;
        USB_EXCLUDE_PRINTER = 0;
      };
    };
  };

  systemd.sleep.extraConfig = "HibernateDelaySec=1h";

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
