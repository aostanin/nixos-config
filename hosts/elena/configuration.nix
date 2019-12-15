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
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = [ "zfs" ];
    zfs.extraPools = [ "spool" ]; # TODO: temporary
    kernelModules = [ "vfio_pci" ];
    kernelParams = [
      "intel_iommu=on"
    ];
  };

  networking = {
    hostName = "elena";
    hostId = "4446d154";

    bridges.br0.interfaces = [ "enp9s0" ];
    interfaces.br0 = {
      macAddress = "26:76:54:CA:95:14";
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
    storageDriver = "zfs";
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
        ${pkgs.rclone}/bin/rclone mount media-union: /srv/media-union \
          --read-only \
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
      ];

      networking = {
        hostName = "aostanin-shell";
        hostId = "1a2fc380";
        interfaces.eth0.useDHCP = true;
      };
    };
  };
}
