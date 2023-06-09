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
in {
  imports = [
    "${hardwareModulesPath}/common/cpu/intel"
    "${hardwareModulesPath}/common/pc/ssd"
    ./hardware-configuration.nix
    ../../modules
    ../../modules/variables
    ../../modules/common
    ../../modules/desktop
    ../../modules/msmtp
    ../../modules/zerotier
    ./backup.nix
    #./i915-sriov.nix
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

    vlans = {
      vlan40 = {
        id = 40;
        interface = "br0";
      };
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

  # TODO: Workaround for network down after resuming from sleep.
  networking.useNetworkd = true;
  #systemd.services.systemd-networkd.environment = {"SYSTEMD_LOG_LEVEL" = "debug";};
  systemd.network = {
    wait-online.timeout = 30;
    # Workaround for "static routes are not configured"
    wait-online.anyInterface = true;
  };

  localModules = {
    pikvm.enable = true;

    scrutinyCollector.enable = true;

    virtwold = {
      enable = true;
      interfaces = ["br0"];
    };
  };

  hardware.nvidia = {
    package = pkgs.nur.repos.arc.packages.nvidia-patch.override {
      nvidia_x11 = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  environment.systemPackages = with pkgs; [
    mstflint
  ];

  services = {
    logind.extraConfig = ''
      HandlePowerKey=suspend
    '';

    xserver = {
      videoDrivers = ["modesetting" "nvidia"];
      deviceSection = ''
        Option "TearFree" "true"
      '';
      xrandrHeads = [
        {
          output = "HDMI-1";
          primary = true;
          monitorConfig = ''
            Option "Position" "0 1440"
          '';
        }
        {
          output = "DP-1";
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

  virtualisation.libvirtd.enable = true;

  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
    storageDriver = "zfs";
    liveRestore = false;
    # Docker defaults to Google's DNS
    extraOptions = ''
      --dns ${secrets.network.home.nameserver} \
      --dns-search lan
    '';
  };

  fileSystems."/mnt/elena" = {
    device = "${secrets.network.storage.hosts.elena.address}:/";
    fsType = "nfs";
    options = ["x-systemd.automount" "x-systemd.idle-timeout=600" "noauto" "noatime"];
  };
}
