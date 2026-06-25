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
    "${inputs.nixos-hardware}/common/pc/ssd"
    ./hardware-configuration.nix
    ./backup.nix
    ./libvirt
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
    localCommands = ''
      # Avoid hang when traffic is high
      # ref: https://forums.servethehome.com/index.php?threads/fix-intel-i219-v-detected-hardware-unit-hang.36700/#post-339318
      ${lib.getExe pkgs.ethtool} -K ${interface} tso off gso off gro off
      ${lib.getExe pkgs.ethtool} --set-eee ${interface} eee off
    '';
  };

  powerManagement.powertop.enable = true;

  localModules = {
    backup = {
      enable = true;
      paths = [
        "/home"
        "/storage/appdata"
        "/var/lib/libvirt"
        "/var/lib/nixos"
        "/var/lib/tailscale"
        "/var/lib/traefik"
      ];
    };

    common.enable = true;

    containers = {
      enable = true;
      storage = {
        default = "/storage/appdata/docker/ssd";
        bulk = "/storage/appdata/docker/bulk";
        temp = "/storage/appdata/temp";
      };
      services = {};
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

    nvtop.package = pkgs.nvtopPackages.intel;

    scrutinyCollector.enable = true;

    tailscale = {
      isServer = true;
      extraFlags = [
        "--advertise-exit-node"
        "--advertise-routes=10.0.40.0/24"
      ];
    };

    watchdog.enable = true;

    zfs.enable = true;
  };

  services = {
    logind.settings.Login.HandleLidSwitch = "ignore";

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

  users.users.${secrets.user.username}.linger = true;

  virtualisation.libvirtd.enable = true;
}
