{ config, pkgs, ... }:

{
  imports = [
    <nixos-hardware/common/cpu/intel>
    <nixos-hardware/common/pc/ssd>
    ./hardware-configuration.nix
    ../../modules/common
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
      "console=ttyS1,115200"
    ];
    extraModprobeConfig = ''
      options kvm ignore_msrs=1
      options kvm-intel nested=1
    '';
    kernel.sysctl = {
      "net.ipv6.conf.br-wan.disable_ipv6" = 1;
      "net.ipv6.conf.br-guest.disable_ipv6" = 1;
    };
  };

  services.mingetty.serialSpeed = [ 115200 ];

  networking = {
    hostName = "elena";
    hostId = "4446d154";

    bridges = {
      br-wan.interfaces = [ "vl-wan" ];
      br-guest.interfaces = [ "vl-guest" ];
      br-lan = {
        interfaces = [ "enp6s0f0" ];
        rstp = true;
      };
    };

    vlans = {
      vl-wan = {
        id = 10;
        interface = "enp6s0f0";
      };
      vl-guest = {
        id = 20;
        interface = "enp6s0f0";
      };
    };

    interfaces.br-lan = {
      useDHCP = true;
      macAddress = "7a:72:12:cc:08:19";
    };
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
      --dns 10.0.0.1 \
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

  services.nfs.server = {
    enable = true;
    # TODO: limit to vlan
    exports = ''
      /srv/nfs        10.0.0.0/24(insecure,rw,fsid=0)
      /srv/nfs/images 10.0.0.0/24(insecure,no_root_squash,rw)
      /srv/nfs/media  10.0.0.0/24(insecure,rw)
    '';
  };

  # Needed for rclone mount
  environment.etc."fuse.conf".text = ''
    user_allow_other
  '';

  # TODO: Clean this up
  systemd.services.media-union-mount = {
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

  containers.shell = {
    autoStart = true;
    privateNetwork = true;
    hostBridge = "br-lan";

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
