{
  config,
  pkgs,
  lib,
  hardwareModulesPath,
  ...
}: let
  secrets = import ../../secrets;
  iface = "enx${lib.replaceStrings [":"] [""] secrets.network.nics.valmar.expansion10GbE0}";
  ifaceStorage = "enx${lib.replaceStrings [":"] [""] secrets.network.nics.valmar.expansion10GbE1}";
  ifaceWol = "enx${lib.replaceStrings [":"] [""] secrets.network.nics.valmar.integrated}";
in {
  imports = [
    "${hardwareModulesPath}/common/cpu/amd"
    "${hardwareModulesPath}/common/pc/ssd"
    ./hardware-configuration.nix
    ../../modules/variables
    ../../modules/common
    ../../modules/desktop
    ../../modules/msmtp
    ../../modules/scrutiny
    ../../modules/zerotier
    ../../modules
    ./backup.nix
    ./telegraf.nix
    ./vfio.nix
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
    tmpOnTmpfs = true;
    extraModulePackages = with config.boot.kernelPackages; [
      zenpower
    ];
    kernelModules = [
      "amdgpu"
      "it87"
    ];
    blacklistedKernelModules = [
      "k10temp" # Use zenpower
      "nouveau"
    ];
    kernelParams = [
      "pcie_aspm.policy=powersave"
    ];
    binfmt.emulatedSystems = ["aarch64-linux"];
    zfs.extraPools = ["tank"];
    zfs.forceImportAll = true;
  };

  hardware = {
    nvidia.package = pkgs.nur.repos.arc.packages.nvidia-patch.override {
      nvidia_x11 = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    opengl.extraPackages = with pkgs; [
      amdvlk
      rocm-opencl-icd
    ];
  };

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

      "${ifaceStorage}" = {
        mtu = 9000;
        ipv4.addresses = [
          {
            address = secrets.network.storage.hosts.valmar.address;
            prefixLength = 24;
          }
        ];
      };

      "${ifaceWol}" = {
        wakeOnLan.enable = true;
      };
    };

    defaultGateway = secrets.network.home.defaultGateway;
    nameservers = [secrets.network.home.nameserverPihole];

    firewall = {
      enable = true;
      trustedInterfaces = [
        "br0"
        ifaceStorage
        secrets.zerotier.interface
      ];
    };
  };

  services = {
    virtwold = {
      enable = true;
      interfaces = ["br0"];
    };

    udev = {
      extraRules = ''
        # Disable Bluetooth dongle passed to Windows VM
        SUBSYSTEM=="usb", ATTRS{idVendor}=="0a12", ATTRS{idProduct}=="0001", ATTRS{busnum}=="1", ATTR{authorized}="0"

        # GPU lower power mode
        KERNEL=="card0", SUBSYSTEM=="drm", DRIVERS=="amdgpu", ATTR{device/power_dpm_force_performance_level}="low"
      '';
      packages = [
        pkgs.stlink
      ];
    };

    xserver = {
      videoDrivers = ["amdgpu" "nvidia"];
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

    zfs = {
      autoScrub = {
        enable = true;
        interval = "monthly";
      };
      trim.enable = true;
      zed = {
        enableMail = true;
        settings = {
          ZED_EMAIL_ADDR = secrets.user.emailAddress;
          ZED_NOTIFY_VERBOSE = true;
        };
      };
    };
  };

  fileSystems = let
    nfsFilesystem = path: {
      device = "${secrets.network.storage.hosts.elena.address}:${path}";
      fsType = "nfs";
    };
  in {
    "/var/lib/libvirt/images/remote" = nfsFilesystem "/images";
    "/mnt/media" = nfsFilesystem "/media";
    "/mnt/personal" = nfsFilesystem "/personal";
  };

  programs.adb.enable = true;

  virtualisation.libvirtd.enable = true;

  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
    storageDriver = "zfs";
    liveRestore = false;
    autoPrune = {
      enable = true;
      flags = [
        "--all"
        "--filter \"until=168h\""
      ];
    };
  };

  # TODO: For temporary development, remove later
  systemd.services.bluetooth = {
    serviceConfig = {
      ExecStart = lib.mkForce [
        ""
        "${pkgs.bluez}/libexec/bluetooth/bluetoothd --compat -f /etc/bluetooth/main.conf"
      ];
    };
  };
}
