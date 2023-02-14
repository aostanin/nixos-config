{
  config,
  pkgs,
  lib,
  hardwareModulesPath,
  ...
}: let
  secrets = import ../../secrets;
  iface = "enx${lib.replaceStrings [":"] [""] secrets.network.nics.elena.expansion10GbE0}";
  ifaceStorage = "enx${lib.replaceStrings [":"] [""] secrets.network.nics.elena.expansion10GbE1}";
in {
  imports = [
    "${hardwareModulesPath}/common/cpu/intel"
    "${hardwareModulesPath}/common/pc/ssd"
    ./hardware-configuration.nix
    ../../modules
    ../../modules/variables
    ../../modules/common
    ../../modules/msmtp
    ../../modules/scrutiny
    ../../modules/zerotier
    ./backup.nix
    ./nfs.nix
    ./telegraf.nix
    ./vfio.nix
    ./power-management.nix
  ];

  boot = {
    loader = {
      grub = {
        enable = true;
        configurationLimit = 10;
        efiSupport = true;
        efiInstallAsRemovable = true;
        mirroredBoots = [
          {
            devices = ["nodev"];
            path = "/boot1";
          }
          {
            devices = ["nodev"];
            path = "/boot2";
          }
        ];
      };
    };
    supportedFilesystems = ["zfs"];
    zfs = {
      extraPools = ["tank"];
      forceImportAll = true;
      requestEncryptionCredentials = false;
    };
    tmpOnTmpfs = true;
    kernelParams = [
      "pcie_aspm.policy=powersave"
    ];
  };

  systemd.network.links."11-default" = {
    matchConfig.OriginalName = "*";
    linkConfig.NamePolicy = "mac";
    linkConfig.MACAddressPolicy = "persistent";
  };

  networking = {
    hostName = "elena";
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
      macAddress = secrets.network.home.hosts.elena.macAddress;
      ipv4.addresses = [
        {
          address = secrets.network.home.hosts.elena.address;
          prefixLength = 24;
        }
      ];
    };

    interfaces.vlan40 = {
      ipv4.addresses = [
        {
          address = secrets.network.iot.hosts.elena.address;
          prefixLength = 24;
        }
      ];
    };

    interfaces."${ifaceStorage}" = {
      mtu = 9000;
      ipv4.addresses = [
        {
          address = secrets.network.storage.hosts.elena.address;
          prefixLength = 24;
        }
      ];
    };

    defaultGateway = secrets.network.home.defaultGateway;
    nameservers = [secrets.network.home.nameserver];

    firewall = {
      # TODO: Breaks some Docker containers
      enable = false;
      trustedInterfaces = [
        "br0"
        "docker0"
        ifaceStorage
        secrets.zerotier.interface
      ];
      interfaces.vlan40 = {
        allowedTCPPorts = [
          1883 # MQTT
        ];
        allowedUDPPorts = [
          123 # NTP
        ];
      };
    };
  };

  hardware = {
    nvidia = {
      nvidiaSettings = false;
      package = pkgs.nur.repos.arc.packages.nvidia-patch.override {
        nvidia_x11 = config.boot.kernelPackages.nvidiaPackages.stable;
      };
    };

    opengl = {
      enable = true;
      driSupport32Bit = true;
    };
  };

  services = {
    virtwold = {
      enable = true;
      interfaces = ["br0"];
    };

    xserver.videoDrivers = ["intel" "nvidia"];

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
    autoPrune = {
      # Don't autoprune on servers
      enable = false;
      flags = [
        "--all"
        "--filter \"until=168h\""
      ];
    };
    # Docker defaults to Google's DNS
    extraOptions = ''
      --dns ${secrets.network.home.nameserver} \
      --dns-search lan
    '';
  };

  systemd = {
    timers = {
      update-mam = {
        wantedBy = ["timers.target"];
        partOf = ["update-mam.service"];
        after = ["network-online.target"];
        timerConfig = {
          OnCalendar = "0/2:00";
          RandomizedDelaySec = "30m";
        };
      };
    };

    services = {
      update-mam = {
        serviceConfig = {
          Type = "oneshot";
          WorkingDirectory = "/storage/appdata/scripts/mam";
          ExecStart = "/storage/appdata/scripts/mam/update_mam.sh";
        };
      };
    };
  };
}
