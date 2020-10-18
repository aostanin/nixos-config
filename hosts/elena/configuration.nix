{ config, pkgs, ... }:
let
  secrets = import ../../secrets;
in
{
  imports = [
    <nixos-hardware/common/cpu/intel>
    <nixos-hardware/common/pc/ssd>
    ./hardware-configuration.nix
    ../../modules/variables
    ../../modules/common
    ../../modules/zerotier
    ../../home
    ./telegraf.nix
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = [ "zfs" ];
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
    ];
    extraModprobeConfig = ''
      options kvm ignore_msrs=1
      options kvm report_ignored_msrs=0
      options kvm-intel nested=1
    '';
  };

  services.mingetty.serialSpeed = [ 115200 ];

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

    defaultGateway = secrets.network.server.defaultGateway;
    nameservers = [ secrets.network.home.nameserver ];
  };

  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "monthly";
    };
    autoSnapshot = {
      enable = true;
      monthly = 0;
    };
    trim.enable = true;
  };

  virtualisation.libvirtd.enable = true;

  virtualisation.docker = {
    enable = true;
    storageDriver = "zfs";
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

  services.nfs.server = {
    enable = true;
    # TODO: limit to vlan
    exports = ''
      /srv/nfs             ${secrets.network.home.defaultGateway}/24(insecure,rw,fsid=0)
      /srv/nfs/images      ${secrets.network.home.defaultGateway}/24(insecure,no_root_squash,rw)
      /srv/nfs/media       ${secrets.network.home.defaultGateway}/24(insecure,rw)
      /srv/nfs/personal    ${secrets.network.home.defaultGateway}/24(insecure,rw)
    '';
  };

  environment.systemPackages = with pkgs; [
    targetcli
  ];

  hardware.pulseaudio = {
    enable = true;
    systemWide = true;
    tcp = {
      enable = true;
      anonymousClients.allowAll = true;
    };
    zeroconf.publish.enable = true;
  };

  # Needed for rclone mount
  environment.etc."fuse.conf".text = ''
    user_allow_other
  '';

  systemd = {
    timers.cleanup-recorded-videos = {
      wantedBy = [ "timers.target" ];
      partOf = [ "cleanup-recorded-videos.service" ];
      timerConfig = {
        OnCalendar = "daily";
        RandomizedDelaySec = "5h";
      };
    };
    services = {
      cleanup-recorded-videos = {
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writers.writePython3 "cleanup-recorded-videos" { } ''
            import glob
            import os

            DIR = '/storage/recorded'
            MIN_FREE_RATIO = 0.1


            def free_ratio():
                statvfs = os.statvfs(DIR)
                return statvfs.f_bavail / statvfs.f_blocks


            def oldest_file():
                files = glob.glob(f'{DIR}/**/*', recursive=True)
                return sorted(files, key=os.path.getctime)[0]


            while free_ratio() < MIN_FREE_RATIO:
                file = oldest_file()
                os.remove(file)
          '';
        };
      };
      # TODO: Clean this up
      media-union-mount = {
        description = "rclone mount media-union";
        documentation = [ "http://rclone.org/docs/" ];
        after = [ "network-online.target" ];
        before = [ "docker.service" ];
        wantedBy = [ "multi-user.target" ];
        path = [ "${config.security.wrapperDir}/.." ];
        serviceConfig = {
          Type = "notify";
          User = "aostanin";
          Group = "users";
          ExecStart = ''
            ${pkgs.rclone}/bin/rclone mount media-union: /storage/media-union \
              --allow-other
          '';
          ExecStop = "${config.security.wrapperDir}/fusermount -uz /storage/media-union";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    };
  };

  containers.shell = {
    autoStart = true;
    privateNetwork = true;
    hostBridge = "br0";

    bindMounts = {
      "/home" = { hostPath = "/home"; isReadOnly = false; };
      "/storage/download" = { hostPath = "/storage/download"; isReadOnly = false; };
      "/storage/media" = { hostPath = "/storage/media"; isReadOnly = false; };
      "/storage/personal" = { hostPath = "/storage/personal"; isReadOnly = false; };
    };

    config = { config, pkgs, ... }: {
      imports = [
        ../../modules/common
        ../../home
      ];

      networking = {
        hostName = "aostanin-shell";
        hostId = "1a2fc380";
        interfaces.eth0.useDHCP = true;
      };
    };
  };
}
