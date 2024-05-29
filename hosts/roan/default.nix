{
  config,
  pkgs,
  lib,
  inputs,
  secrets,
  ...
}: let
  interface = "enx${lib.replaceStrings [":"] [""] secrets.network.nics.roan.integrated}";
in {
  imports = [
    "${inputs.nixos-hardware}/lenovo/thinkpad/x250"
    "${inputs.nixos-hardware}/common/pc/laptop/ssd"
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
      "zfs.zfs_arc_max=2147483648"
      "msr.allow_writes=on" # For undervolt
    ];
    binfmt.emulatedSystems = ["aarch64-linux"];
  };

  networking = {
    hostName = "roan";
    hostId = "9bc52069";
    localCommands = ''
      # Avoid hang when traffic is high
      # ref: https://forums.servethehome.com/index.php?threads/fix-intel-i219-v-detected-hardware-unit-hang.36700/#post-339318
      ${pkgs.ethtool}/bin/ethtool -K ${interface} tso off gso off
    '';
  };

  powerManagement.powertop.enable = true;

  localModules = {
    common.enable = true;

    docker = {
      enable = true;
      useLocalDns = true;
    };

    home-server = {
      enable = true;
      interface = interface;
      address = secrets.network.home.hosts.roan.address;
      macAddress = secrets.network.home.hosts.roan.macAddress;
      iotNetwork = {
        enable = true;
        address = secrets.network.iot.hosts.roan.address;
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
        START_CHARGE_THRESH_BAT0 = 85;
        STOP_CHARGE_THRESH_BAT0 = 90;
        START_CHARGE_THRESH_BAT1 = 85;
        STOP_CHARGE_THRESH_BAT1 = 90;
      };
    };

    undervolt = {
      enable = true;
      coreOffset = -40;
      gpuOffset = -30;
    };

    xserver.videoDrivers = ["modesetting"];
  };

  virtualisation.libvirtd.enable = true;
}
