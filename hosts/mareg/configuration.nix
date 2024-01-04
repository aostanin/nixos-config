{
  config,
  pkgs,
  lib,
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
  };

  powerManagement.powertop.enable = true;

  localModules = {
    docker = {
      enable = true;
      useLocalDns = true;
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

    intelAmt.enable = true;

    scrutinyCollector.enable = true;

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

    xserver.videoDrivers = ["modesetting"];
  };

  hardware = {
    nvidiaOptimus.disable = true;
  };

  virtualisation.libvirtd.enable = true;
}
