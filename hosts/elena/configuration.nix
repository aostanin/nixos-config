{ config, pkgs, ... }:

let
  nixos-hardware = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
  };
in {
  imports = [
    "${nixos-hardware}/common/cpu/intel/sandy-bridge"
    "${nixos-hardware}/common/pc/laptop/ssd"
    ./hardware-configuration.nix
    ../../modules/common
  ];

  boot = {
    loader = {
      # TODO: not uefi
      systemd-boot.enable = true;
    };
    supportedFilesystems = [ "zfs" ];
  };

  networking = {
    hostName = "elena";
    hostId = "4446d154";
  };

  services.zfs = {
    autoScrub.enable = true;
    autoSnapshot = {
      enable = true;
      monthly = 0;
    };
  };
}
