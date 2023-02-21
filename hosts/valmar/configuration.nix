{
  config,
  pkgs,
  lib,
  hardwareModulesPath,
  ...
}: let
  secrets = import ../../secrets;
  iface = "enx${lib.replaceStrings [":"] [""] secrets.network.nics.valmar.integrated}";
in {
  imports = [
    "${hardwareModulesPath}/common/cpu/intel/cpu-only.nix"
    "${hardwareModulesPath}/common/pc/ssd"
    ./hardware-configuration.nix
    ../../modules/variables
    ../../modules/common
    ../../modules/desktop
    ../../modules/msmtp
    ../../modules/zerotier
    ../../modules
    ./power-management.nix
  ];

  variables = {
    hasBattery = false;
    hasBacklightControl = false;
    hasDesktop = true;
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = ["zfs"];
    zfs.allowHibernation = true;
    tmpOnTmpfs = true;
    extraModulePackages = with config.boot.kernelPackages; [
      kvmfr
    ];
    kernelModules = [
      "amdgpu"
    ];
    kernelParams = [
      # For virsh console
      "console=ttyS0,115200"
      "console=tty1"
    ];
  };

  hardware.opengl.extraPackages = with pkgs; [
    amdvlk
    rocm-opencl-icd
  ];

  systemd.network.links."11-default" = {
    matchConfig.OriginalName = "*";
    linkConfig.NamePolicy = "mac";
    linkConfig.MACAddressPolicy = "persistent";
  };

  networking = {
    hostName = "valmar";
    hostId = "203d588e";

    bridges.br0.interfaces = [iface];

    vlans = {
      vlan40 = {
        id = 40;
        interface = "br0";
      };
    };

    interfaces = {
      br0 = {
        macAddress = secrets.network.home.hosts.valmar.macAddress;
        ipv4.addresses = [
          {
            address = secrets.network.home.hosts.valmar.address;
            prefixLength = 24;
          }
        ];
      };

      vlan40 = {
        ipv4.addresses = [
          {
            address = secrets.network.iot.hosts.valmar.address;
            prefixLength = 24;
          }
        ];
      };
    };

    defaultGateway = secrets.network.home.defaultGateway;
    nameservers = [secrets.network.home.nameserverPihole];

    firewall = {
      enable = true;
      trustedInterfaces = [
        "br0"
        secrets.zerotier.interface
      ];
    };
  };

  services = {
    qemuGuest.enable = true;

    udev.packages = with pkgs; [
      stlink
    ];

    xserver = {
      videoDrivers = ["amdgpu"];
      deviceSection = ''
        Option "TearFree" "true"
      '';
      xrandrHeads = [
        {
          output = "HDMI-A-0";
          primary = true;
          monitorConfig = ''
            Option "Position" "0 1440"
          '';
        }
        {
          output = "DVI-D-0";
          monitorConfig = ''
            Option "Position" "440 0"
          '';
        }
      ];
    };
  };

  virtualisation = {
    libvirtd.enable = true;

    docker = {
      enable = true;
      liveRestore = false;
      autoPrune = {
        enable = true;
        flags = [
          "--all"
          "--filter \"until=168h\""
        ];
      };
    };
  };
}
