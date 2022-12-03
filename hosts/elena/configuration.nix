{
  config,
  pkgs,
  hardwareModulesPath,
  ...
}: let
  secrets = import ../../secrets;
  iface = "enp4s0f0";
  ifaceStorage = "enp4s0f1";
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
    ./telegraf.nix
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = ["zfs"];
    tmpOnTmpfs = true;
    kernelParams = [
      "i915.force_probe=4690" # TODO: Remove after upgrading to 5.16+ kernel
      "i915.enable_fbc=1"
      "i915.enable_guc=3"
      "pcie_aspm.policy=powersave"
      #"vfio-pci.ids=1912:0014" # USB
    ];
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
    vfio = {
      enable = true;
      cpuType = "intel";
      gpu = {
        # Quadro P400
        driver = "nvidia";
        pciIds = ["10de:1cb3" "10de:0fb9"];
        busId = "01:00.0";
      };
      vms = {
        win10-work = {
          useGpu = false;
          enableHibernation = true;
        };
        win10-work-gpu = {
          useGpu = true;
          enableHibernation = true;
        };
      };
    };

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
      autoSnapshot = {
        enable = true;
        monthly = 0;
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

    znapzend = {
      enable = true;
      pure = true;
      autoCreation = true;
      features = {
        compressed = true;
        recvu = true;
        skipIntermediates = true;
        zfsGetType = true;
      };
      zetup = {
        "tank/home" = {
          plan = "1day=>1hour,1week=>1day,1month=>1week";
          destinations.remote = {
            host = secrets.network.storage.hosts.valmar.address;
            dataset = "tank/backup/hosts/zfs/${config.networking.hostName}/home";
            plan = "1week=>1day,1month=>1week,3month=>1month";
          };
        };
        "tank/root/nixos" = {
          recursive = true;
          plan = "1day=>1hour,1week=>1day,1month=>1week";
          destinations.remote = {
            host = secrets.network.storage.hosts.valmar.address;
            dataset = "tank/backup/hosts/zfs/${config.networking.hostName}/root/nixos";
            plan = "1week=>1day,1month=>1week,3month=>1month";
          };
        };
        "tank/appdata/docker" = {
          recursive = true;
          plan = "1day=>1hour,1week=>1day,1month=>1week";
          destinations.remote = {
            host = secrets.network.storage.hosts.valmar.address;
            dataset = "tank/backup/hosts/zfs/${config.networking.hostName}/appdata/docker";
            plan = "1week=>1day,1month=>1week,3month=>1month";
          };
        };
        "tank/personal" = {
          recursive = true;
          plan = "1day=>1hour,1week=>1day,1month=>1week";
          destinations.remote = {
            host = secrets.network.storage.hosts.valmar.address;
            dataset = "tank/backup/hosts/zfs/${config.networking.hostName}/personal";
            plan = "1week=>1day,1month=>1week,3month=>1month";
          };
        };
        "tank/media/music" = {
          recursive = true;
          plan = "1day=>1hour,1week=>1day,1month=>1week";
          destinations.remote = {
            host = secrets.network.storage.hosts.valmar.address;
            dataset = "tank/backup/hosts/zfs/${config.networking.hostName}/media/music";
            plan = "1week=>1day,1month=>1week,3month=>1month";
          };
        };
        "tank/media/audiobooks" = {
          recursive = true;
          plan = "1day=>1hour,1week=>1day,1month=>1week";
          destinations.remote = {
            host = secrets.network.storage.hosts.valmar.address;
            dataset = "tank/backup/hosts/zfs/${config.networking.hostName}/media/audiobooks";
            plan = "1week=>1day,1month=>1week,3month=>1month";
          };
        };
        "tank/media/books" = {
          recursive = true;
          plan = "1day=>1hour,1week=>1day,1month=>1week";
          destinations.remote = {
            host = secrets.network.storage.hosts.valmar.address;
            dataset = "tank/backup/hosts/zfs/${config.networking.hostName}/media/books";
            plan = "1week=>1day,1month=>1week,3month=>1month";
          };
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
      enable = true;
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

  fileSystems."/srv/nfs/images" = {
    device = "/var/lib/libvirt/images";
    options = ["bind"];
  };

  fileSystems."/srv/nfs/media" = {
    device = "/storage/media";
    options = ["bind"];
  };

  fileSystems."/srv/nfs/personal" = {
    device = "/storage/personal";
    options = ["bind"];
  };

  services.nfs.server = {
    enable = true;
    hostName = secrets.network.storage.hosts.elena.address;
    exports = ''
      /srv/nfs             ${secrets.network.storage.hosts.elena.address}/24(insecure,rw,fsid=0)
      /srv/nfs/images      ${secrets.network.storage.hosts.elena.address}/24(insecure,no_root_squash,rw,crossmnt)
      /srv/nfs/media       ${secrets.network.storage.hosts.elena.address}/24(insecure,rw,crossmnt)
      /srv/nfs/personal    ${secrets.network.storage.hosts.elena.address}/24(insecure,rw)
    '';
  };

  services.rsync-backup = {
    enable = true;
    backups = {
      vps-gce1 = {
        source = "root@${secrets.network.zerotier.hosts.vps-gce1.address}:/storage/appdata";
        destination = "/storage/backup/hosts/dir/vps-gce1";
      };
      vps-oci1 = {
        source = "root@${secrets.network.zerotier.hosts.vps-oci1.address}:/storage/appdata";
        destination = "/storage/backup/hosts/dir/vps-oci1";
      };
      vps-oci2 = {
        source = "root@${secrets.network.zerotier.hosts.vps-oci2.address}:/storage/appdata";
        destination = "/storage/backup/hosts/dir/vps-oci2";
      };
    };
  };

  systemd = {
    timers = {
      update-mam = {
        wantedBy = ["timers.target"];
        partOf = ["update-mam.service"];
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
