{ config, pkgs, ... }:

let
  nixos-hardware = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
  };
in {
  imports = [
    "${nixos-hardware}/common/cpu/intel/sandy-bridge"
    "${nixos-hardware}/common/pc/ssd"
    ./hardware-configuration.nix
    ../../modules/common
  ];

  boot = {
    loader = {
      # TODO: not uefi
      systemd-boot.enable = true;
    };
    supportedFilesystems = [ "zfs" ];
    kernelModules = [ "vfio_pci" ];
    kernelParams = [
      "intel_iommu=on"
    ];
  };

  networking = {
    hostName = "elena";
    hostId = "4446d154";
    interfaces.enp2s0f0 = {
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
    autoScrub.enable = true;
    autoSnapshot = {
      enable = true;
      monthly = 0;
    };
    trim.enable = true;
  };

  virtualisation.libvirtd.enable = true;
}
