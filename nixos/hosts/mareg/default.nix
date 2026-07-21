{
  config,
  pkgs,
  lib,
  inputs,
  secrets,
  ...
}: {
  imports = [
    "${inputs.nixos-hardware}/lenovo/thinkpad/t440p"
    "${inputs.nixos-hardware}/common/pc/ssd"
    ./hardware-configuration.nix
    ./backup.nix
  ];

  boot = {
    loader = {
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        zfsSupport = true;
        configurationLimit = 10;
        mirroredBoots = [
          {
            devices = ["nodev"];
            path = "/boot1";
            efiSysMountPoint = "/boot1";
          }
          {
            devices = ["nodev"];
            path = "/boot2";
            efiSysMountPoint = "/boot2";
          }
        ];
      };
    };
    tmp.useTmpfs = true;
    blacklistedKernelModules = ["nouveau"];
    kernelParams = [
      "intel_iommu=on"
      "iommu=pt"
      "intel_pstate=active"
      "i915.enable_fbc=1"
      "zfs.zfs_arc_max=${toString (2 * 1024 * 1024 * 1024)}"
      "iomem=relaxed" # To flash firmware
    ];
    binfmt.emulatedSystems = ["aarch64-linux"];
  };

  networking = {
    hostName = "mareg";
    hostId = "393740af";

    # Lean host: static LAN on the integrated NIC (router role lives on elena).
    useNetworkd = true;
    useDHCP = false;
  };

  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "enx*";
      address = ["${secrets.network.home.hosts.mareg.address}/24"];
      routes = [{Gateway = secrets.network.home.defaultGateway;}];
      networkConfig.DNS = [secrets.network.home.nameserver];
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


    containers = {
      enable = true;
      storage = {
        default = "/persist/safe/appdata/containers/data";
        bulk = "/persist/safe/appdata/containers/bulk";
        temp = "/persist/cache/appdata/containers/temp";
      };
      services = {};
    };

    impermanence.enable = true;

    intelAmt.enable = true;

    nvtop.package = pkgs.nvtopPackages.intel;

    scrutinyCollector.enable = true;

    tailscale = {
      isServer = true;
      extraFlags = ["--advertise-exit-node"];
    };

    watchdog.enable = true;

    zfs.enable = true;
  };

  services = {
    logind.settings.Login.HandleLidSwitch = "ignore";

    tlp = {
      enable = true;
      settings = {
        USB_AUTOSUSPEND = 0;
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };
  };
}
