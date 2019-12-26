{ config, pkgs, ... }:

let
  nixos-hardware = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
  };
in {
  imports = [
    "${nixos-hardware}/common/cpu/intel"
    "${nixos-hardware}/common/pc/ssd"
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
    zfs.extraPools = [ "spool" ]; # TODO: temporary
    kernelModules = [
      "nct6775" # For lm-sensors
      "vfio_pci"
    ];
    kernelParams = [
      "zfs.zfs_arc_min=34359738368"
      "zfs.zfs_arc_max=51539607552"
      # TODO: After memory upgrade
      # "zfs.zfs_arc_min=68719476736"
      # "zfs.zfs_arc_max=103079215104"
      "intel_iommu=on"
      "iommu=pt"
      "console=tty0"
      "console=ttyS1,115200"
    ];
    extraModprobeConfig = ''
      options kvm ignore_msrs=1
    '';
  };

  services.mingetty.serialSpeed = [ 115200 ];

  networking = {
    hostName = "elena";
    hostId = "4446d154";

    useDHCP = false;

    bridges.br0.interfaces = [ "enp9s0" ];
    interfaces.br0 = {
      useDHCP = true;
    };

    interfaces.enp3s0f0 = {
      ipv4.addresses = [ {
        address = "192.168.10.1";
        prefixLength = 24;
      } ];
      mtu = 9000;
    };
    hosts = {
      "192.168.10.2" = [ "valmar-10g" ];
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
      --dns 192.168.1.1 \
      --dns-search lan
    '';
  };

  # Needed for rclone mount
  environment.etc."fuse.conf".text = ''
    user_allow_other
  '';

  fileSystems."/srv/nfs/images" = {
    device = "/var/lib/libvirt/images";
    options = [ "bind" ];
  };

  fileSystems."/srv/nfs/media" = {
    device = "/srv/media";
    options = [ "bind" ];
  };

  services.nfs.server = {
    enable = true;
    exports = ''
      /srv/nfs        192.168.10.0/24(insecure,rw,fsid=0)
      /srv/nfs/images 192.168.10.0/24(insecure,no_root_squash,rw)
      /srv/nfs/media  192.168.10.0/24(insecure,rw)
    '';
  };

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
        ${pkgs.rclone}/bin/rclone mount media-union: /srv/media-union \
          --allow-other
      '';
      ExecStop = "${config.security.wrapperDir}/fusermount -uz /srv/media-union";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  containers.shell = {
    autoStart = true;
    privateNetwork = true;
    hostBridge = "br0";

    bindMounts = {
      "/home" = { hostPath = "/home"; isReadOnly = false; };
      "/srv/download" = { hostPath = "/srv/download"; isReadOnly = false; };
      "/srv/media" = { hostPath = "/srv/media"; isReadOnly = false; };
      "/srv/photos" = { hostPath = "/srv/photos"; isReadOnly = false; };
      "/srv/sync" = { hostPath = "/srv/sync"; isReadOnly = false; };
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
