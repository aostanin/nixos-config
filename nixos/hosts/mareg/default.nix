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
      "iomem=relaxed" # To flash firmware
    ];
    binfmt.emulatedSystems = ["aarch64-linux"];
  };

  networking = {
    hostName = "mareg";
    hostId = "393740af";
  };

  powerManagement.powertop.enable = true;

  localModules = {
    backup = {
      enable = true;
      paths = [
        "/home"
        "/persist"
      ];
    };

    common.enable = true;

    containers = {
      enable = true;
      storage = {
        default = "/storage/appdata/containers/storage";
        bulk = "/storage/appdata/containers/bulk";
        temp = "/storage/appdata/temp";
      };
      services = {
        ollama.enable = true;
        whoami.enable = true;
      };
    };

    home-server = {
      enable = true;
      interface = "enx${lib.replaceStrings [":"] [""] secrets.network.nics.mareg.integrated}";
      address = secrets.network.home.hosts.mareg.address;
      macAddress = secrets.network.home.hosts.mareg.macAddress;
      iotNetwork = {
        enable = true;
        address = secrets.network.iot.hosts.mareg.address;
      };
    };

    impermanence.enable = true;

    intelAmt.enable = true;

    nvtop.package = pkgs.nvtopPackages.intel;

    scrutinyCollector.enable = true;

    tailscale = {
      isServer = true;
      extraFlags = [
        "--advertise-exit-node"
        "--advertise-routes=10.0.40.0/24"
      ];
    };

    zfs.enable = true;
  };

  services = {
    logind.lidSwitch = "ignore";

    tlp = {
      enable = true;
      settings = {
        USB_AUTOSUSPEND = 0;
        START_CHARGE_THRESH_BAT0 = 85;
        STOP_CHARGE_THRESH_BAT0 = 90;
      };
    };
  };

  virtualisation.libvirtd.enable = true;
}
