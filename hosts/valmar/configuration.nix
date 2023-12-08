{
  config,
  pkgs,
  lib,
  hardwareModulesPath,
  secrets,
  ...
}: let
  iface = "enx${lib.replaceStrings [":"] [""] secrets.network.nics.valmar.expansion10GbE0}";
  ifaceStorage = "enx${lib.replaceStrings [":"] [""] secrets.network.nics.valmar.expansion10GbE1}";
in {
  imports = [
    "${hardwareModulesPath}/common/cpu/intel"
    "${hardwareModulesPath}/common/pc/ssd"
    ./hardware-configuration.nix
    ../../modules
    ../../modules/common
    ../../modules/msmtp
    ../../modules/zerotier
    ./backup.nix
    #./i915-sriov.nix
    ./vfio.nix
    ./power-management.nix
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
      "i915.enable_fbc=1"
    ];
    binfmt.emulatedSystems = ["aarch64-linux"];
  };

  systemd.network.links."11-default" = {
    matchConfig.OriginalName = "*";
    linkConfig.NamePolicy = "mac";
    linkConfig.MACAddressPolicy = "persistent";
  };

  networking = {
    hostName = "valmar";
    hostId = "4446d154";

    vlans.vlan40 = {
      id = 40;
      interface = "br0";
    };

    # Home LAN, IPoE uplink
    bridges.br0.interfaces = [iface];
    interfaces.br0 = {
      macAddress = secrets.network.home.hosts.valmar.macAddress;
      ipv4.addresses = [
        {
          address = secrets.network.home.hosts.valmar.address;
          prefixLength = 24;
        }
      ];
    };

    interfaces.vlan40 = {
      ipv4.addresses = [
        {
          address = secrets.network.iot.hosts.valmar.address;
          prefixLength = 24;
        }
      ];
    };

    interfaces."${ifaceStorage}" = {
      mtu = 9000;
      ipv4.addresses = [
        {
          address = secrets.network.storage.hosts.valmar.address;
          prefixLength = 24;
        }
      ];
    };

    defaultGateway = secrets.network.home.defaultGateway;
    nameservers = secrets.network.home.nameserversAdguard;
  };

  localModules = {
    desktop = {
      enable = true;
      primaryOutput = "HDMI-A-1";
      output = {
        "*" = {
          bg = "~/Sync/wallpaper/nix-wallpaper-nineish-dark-gray.png fill";
        };
        "HDMI-A-1" = {
          pos = "0,1440";
        };
        "DP-1" = {
          pos = "440,0";
        };
      };
      preStartCommands = ''
        export WLR_DRM_DEVICES=$(readlink -f /dev/dri/by-path/pci-0000:00:02.0-card)
        export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json
      '';
      workspaceOutputAssign = builtins.map (x: {
        workspace = builtins.toString x;
        output =
          if (lib.mod x 2) == 1
          then "HDMI-A-1"
          else "DP-1";
      }) [1 2 3 4 5 6 7 8 9];
    };

    docker = {
      enable = true;
      useLocalDns = true;
    };

    pikvm.enable = true;

    rkvm.server = {
      enable = true;
      listen = "${secrets.network.home.hosts.valmar.address}:5258";
      certificate = secrets.rkvm.certificate;
      key = secrets.rkvm.key;
      password = secrets.rkvm.password;
    };

    scrutinyCollector.enable = true;

    virtwold = {
      enable = true;
      interfaces = ["br0"];
    };

    zfs.enable = true;
  };

  services = {
    logind.extraConfig = ''
      HandlePowerKey=suspend
    '';

    xserver.videoDrivers = ["modesetting" "nvidia"];
  };

  virtualisation = {
    libvirtd.enable = true;

    waydroid.enable = true;
  };

  fileSystems."/mnt/elena" = {
    device = "${secrets.network.storage.hosts.elena.address}:/";
    fsType = "nfs";
    options = ["x-systemd.automount" "x-systemd.idle-timeout=600" "noauto" "noatime"];
  };
}
