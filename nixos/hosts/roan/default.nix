{
  config,
  pkgs,
  lib,
  inputs,
  secrets,
  ...
}: {
  imports = [
    "${inputs.nixos-hardware}/lenovo/thinkpad/x250"
    "${inputs.nixos-hardware}/common/pc/ssd"
    ./hardware-configuration.nix
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
      "zfs.zfs_arc_max=${toString (2 * 1024 * 1024 * 1024)}"
      "msr.allow_writes=on" # For undervolt
    ];
    binfmt.emulatedSystems = ["aarch64-linux"];
  };

  networking = {
    hostName = "roan";
    hostId = "9bc52069";
    firewall = {
      enable = true;
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        } # KDE Connect
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        } # KDE Connect
      ];
      interfaces.tailscale0 = {
        allowedTCPPorts = [
          22 # SSH
          22000 # Syncthing
        ];
        allowedUDPPorts = [
          5353 # Avahi
          22000 # Syncthing
          21027 # Syncthing
        ];
      };
    };
  };

  powerManagement.powertop.enable = true;

  localModules = {
    backup = {
      enable = true;
      paths = [
        "/home"
        "/persist/safe"
      ];
    };

    common.enable = true;

    desktop.enable = true;

    impermanence.enable = true;

    networkmanager.enable = true;

    nvtop.package = pkgs.nvtopPackages.intel;

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

  services = {
    fwupd.enable = true;

    logind.settings.Login = let
      mode = "suspend";
    in {
      HandleLidSwitch = mode;
      HandleLidSwitchDocked = mode;
      HandlePowerKey = mode;
    };

    tlp = {
      enable = true;
      settings = {
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
  };

  systemd.sleep.settings.Sleep.HibernateDelaySec = "1h";
}
