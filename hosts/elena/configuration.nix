{ config, pkgs, hardwareModulesPath, ... }:
let
  secrets = import ../../secrets;
in
{
  imports = [
    "${hardwareModulesPath}/common/cpu/intel"
    "${hardwareModulesPath}/common/pc/ssd"
    ./hardware-configuration.nix
    ../../modules/variables
    ../../modules/common
    ../../modules/scrutiny
    ../../modules/ssmtp
    ../../modules/zerotier
    ./telegraf.nix
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = [ "zfs" ];
    initrd.kernelModules = [
      "vfio_pci"
    ];
    kernelModules = [
      "nct6775" # For lm-sensors
      "vfio_pci"
    ];
    kernelParams = [
      "zfs.zfs_arc_min=68719476736"
      "zfs.zfs_arc_max=103079215104"
      "intel_iommu=on"
      "iommu=pt"
      "console=tty0"
      "console=ttyS1,115200" # IPMI
      "vfio-pci.ids=1912:0014" # USB
    ];
    extraModprobeConfig = ''
      options kvm ignore_msrs=1
      options kvm report_ignored_msrs=0
      options kvm-intel nested=1
    '';
  };

  networking = {
    hostName = "elena";
    hostId = "4446d154";

    # Home LAN, IPoE uplink
    bridges.br0.interfaces = [ "enp6s0f0" ];
    interfaces.br0 = {
      macAddress = secrets.network.home.hosts.elena.macAddress;
      ipv4.addresses = [{
        address = secrets.network.home.hosts.elena.address;
        prefixLength = 24;
      }];
    };

    # Server LAN, PPPoE uplink
    bridges.br1.interfaces = [ ];
    interfaces.br1 = {
      macAddress = secrets.network.server.hosts.elena.macAddress;
      ipv4.addresses = [{
        address = secrets.network.server.hosts.elena.address;
        prefixLength = 24;
      }];
    };

    interfaces.enp6s0f1 = {
      mtu = 9000;
      ipv4.addresses = [{
        address = secrets.network.storage.hosts.elena.address;
        prefixLength = 24;
      }];
    };

    defaultGateway = secrets.network.server.defaultGateway;
    nameservers = [ secrets.network.home.nameserver ];
  };

  services = {
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", KERNELS=="0000:06:00.0", ATTR{device/sriov_numvfs}="32"
      # TODO: Temporary workaround for MTU not being set
      ACTION=="add", SUBSYSTEM=="net", KERNELS=="0000:06:00.1", ATTR{mtu}="9000"
    '';

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
        zfsGetType = true;
      };
      zetup = {
        "tank/home" = {
          plan = "1day=>1hour,1week=>1day,1month=>1week";
          destinations.remote = {
            host = "valmar";
            dataset = "tank/backup/hosts/${config.networking.hostName}/home";
            plan = "1week=>1day,1month=>1week,3month=>1month";
          };
        };
        "tank/nixos" = {
          recursive = true;
          plan = "1day=>1hour,1week=>1day,1month=>1week";
          destinations.remote = {
            host = "valmar";
            dataset = "tank/backup/hosts/${config.networking.hostName}/root/nixos";
            plan = "1week=>1day,1month=>1week,3month=>1month";
          };
        };
        "tank/appdata/docker" = {
          recursive = true;
          plan = "1day=>1hour,1week=>1day,1month=>1week";
          destinations.remote = {
            host = "valmar";
            dataset = "tank/backup/hosts/${config.networking.hostName}/appdata/docker";
            plan = "1week=>1day,1month=>1week,3month=>1month";
          };
        };
        "tank/personal" = {
          recursive = true;
          plan = "1day=>1hour,1week=>1day,1month=>1week";
          destinations.remote = {
            host = "valmar";
            dataset = "tank/backup/hosts/${config.networking.hostName}/personal";
            plan = "1week=>1day,1month=>1week,3month=>1month";
          };
        };
        "tank/media/music" = {
          recursive = true;
          plan = "1day=>1hour,1week=>1day,1month=>1week";
          destinations.remote = {
            host = "valmar";
            dataset = "tank/backup/hosts/${config.networking.hostName}/media/music";
            plan = "1week=>1day,1month=>1week,3month=>1month";
          };
        };
        "tank/media/audiobooks" = {
          recursive = true;
          plan = "1day=>1hour,1week=>1day,1month=>1week";
          destinations.remote = {
            host = "valmar";
            dataset = "tank/backup/hosts/${config.networking.hostName}/media/audiobooks";
            plan = "1week=>1day,1month=>1week,3month=>1month";
          };
        };
        "tank/media/books" = {
          recursive = true;
          plan = "1day=>1hour,1week=>1day,1month=>1week";
          destinations.remote = {
            host = "valmar";
            dataset = "tank/backup/hosts/${config.networking.hostName}/media/books";
            plan = "1week=>1day,1month=>1week,3month=>1month";
          };
        };
      };
    };
  };

  virtualisation.libvirtd.enable = true;

  virtualisation.docker = {
    enable = true;
    storageDriver = "zfs";
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
    options = [ "bind" ];
  };

  fileSystems."/srv/nfs/media" = {
    device = "/storage/media";
    options = [ "bind" ];
  };

  fileSystems."/srv/nfs/personal" = {
    device = "/storage/personal";
    options = [ "bind" ];
  };

  fileSystems."/srv/nfs/games" = {
    device = "/storage/appdata/games";
    options = [ "bind" ];
  };

  services.nfs.server = {
    enable = true;
    exports = ''
      /srv/nfs             ${secrets.network.storage.hosts.elena.address}/24(insecure,rw,fsid=0)
      /srv/nfs/images      ${secrets.network.storage.hosts.elena.address}/24(insecure,no_root_squash,rw,crossmnt)
      /srv/nfs/media       ${secrets.network.storage.hosts.elena.address}/24(insecure,rw,crossmnt)
      /srv/nfs/personal    ${secrets.network.storage.hosts.elena.address}/24(insecure,rw)
      /srv/nfs/games       ${secrets.network.storage.hosts.elena.address}/24(insecure,rw)
    '';
  };

  environment.systemPackages = with pkgs; [
    targetcli
  ];

  # Needed for rclone mount
  environment.etc."fuse.conf".text = ''
    user_allow_other
  '';

  systemd = {
    timers = {
      cleanup-recorded-videos = {
        wantedBy = [ "timers.target" ];
        partOf = [ "cleanup-recorded-videos.service" ];
        timerConfig = {
          OnCalendar = "daily";
          RandomizedDelaySec = "5h";
        };
      };
    };
    services = {
      cleanup-recorded-videos = {
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writers.writePython3 "cleanup-recorded-videos" { } ''
            import glob
            import os

            DIR = '/storage/media/recorded'
            MAX_USED_SPACE = 1 * 1024 * 1024 * 1024 * 1024  # 1 TB


            def used_space():
                files = glob.glob(f'{DIR}/**/*', recursive=True)
                return sum([os.stat(file).st_size for file in files])


            def oldest_file():
                files = glob.glob(f'{DIR}/**/*', recursive=True)
                return sorted(files, key=os.path.getctime)[0]


            while used_space() > MAX_USED_SPACE:
                file = oldest_file()
                os.remove(file)
          '';
        };
      };
      iscsi-target = {
        description = "Restore LIO kernel target configuration";
        after = [ "sys-kernel-config.mount" "network.target" "local-fs.target" ];
        requires = [ "sys-kernel-config.mount" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = "yes";
          ExecStart = "${pkgs.pythonPackages.rtslib}/bin/targetctl restore /etc/target/saveconfig.json";
          ExecStop = "${pkgs.pythonPackages.rtslib}/bin/targetctl clear";
          SyslogIdentifier = "target";
        };
        wantedBy = [ "multi-user.target" ];
        path = with pkgs; [ kmod utillinux ];
      };
    };
  };
}
