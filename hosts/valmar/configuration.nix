{ config, pkgs, ... }:

let
  nixos-hardware = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
  };
  pkgsUnstable = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz";
  }) {};
in {
  imports = [
    "${nixos-hardware}/common/cpu/intel"
    "${nixos-hardware}/common/pc/ssd"
    ./hardware-configuration.nix
    ../../modules/common
    ../../modules/desktop
    ../../modules/syncthing
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "valmar";
    hostId = "203d588e";
    bridges.br0.interfaces = [ "enp0s31f6" ];
  };

  services.flatpak.enable = true;

  services.openssh.forwardX11 = true;

  services.xserver = {
    xkbOptions = "ctrl:nocaps, shift:both_capslock";
  };

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.extraPools = [ "tank" ];
  services.zfs.autoScrub.enable = true;
  services.zfs.autoSnapshot.enable = true;

  systemd.services.iscsid = {
    wantedBy = [ "multi-user.target" ];
    before = ["libvirtd.service"];
    serviceConfig.ExecStart = "${pkgs.openiscsi}/bin/iscsid -f -c ${pkgs.openiscsi}/etc/iscsi/iscsid.conf -i ${pkgs.openiscsi}/etc/iscsi/initiatorname.iscsi";
    restartIfChanged = false;
  };

  nixpkgs.overlays = [
    (self: super: {
      libvirt = super.libvirt.override {
        enableIscsi = true;
      };
    })
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemuPackage = pkgsUnstable.qemu; # TODO: until 4.0 is stable
    qemuVerbatimConfig = ''
      user = "aostanin"
      cgroup_device_acl = [
        "/dev/null", "/dev/full", "/dev/zero",
        "/dev/random", "/dev/urandom",
        "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
        "/dev/rtc","/dev/hpet", "/dev/sev",
        "/dev/input/by-id/usb-04d9_USB_Keyboard-event-kbd",
        "/dev/input/by-id/usb-Logitech_G500s_Laser_Gaming_Mouse_2881723C750008-event-mouse"
      ]
    '';
  };

  boot.kernelModules = [ "vfio_pci" ];
  boot.kernelParams = [
    "intel_iommu=on"
    "vfio-pci.ids=10de:1b81,10de:10f0,1b21:1242"
    "default_hugepagesz=1G" "hugepagesz=1G" "hugepages=16"
  ];
}
