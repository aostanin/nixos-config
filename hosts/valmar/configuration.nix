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
    ../../modules/systemd-patched
    ../../modules/common
    ../../modules/desktop
    ../../modules/mullvad-vpn
    ../../modules/syncthing
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    blacklistedKernelModules = [ "nouveau" ];
  };

  networking = {
    hostName = "valmar";
    hostId = "203d588e";
    bridges.br0.interfaces = [ "enp0s31f6" ];
  };

  services.flatpak.enable = true;

  services.xserver = {
    xkbOptions = "ctrl:nocaps, shift:both_capslock";
    videoDrivers = [ "intel" /*"nvidia"*/ ]; # TODO: enabling nvidia disables glx
  };

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.extraPools = [ "tank" ];
  services.zfs.autoScrub.enable = true;
  services.zfs.autoSnapshot.enable = true;

  environment.etc."iscsi/initiatorname.iscsi".text = "InitiatorName=iqn.2005-03.org.open-iscsi:c1aa1469c14";
  systemd.services.iscsid = {
    wantedBy = [ "multi-user.target" ];
    before = [ "libvirtd.service" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "forking";
      ExecStart = "${pkgs.openiscsi}/bin/iscsid -c ${pkgs.openiscsi}/etc/iscsi/iscsid.conf";
      ExecStop = [
        "${pkgs.openiscsi}/sbin/iscsiadm iscsiadm --mode node --logoutall=all"
        "${pkgs.openiscsi}/sbin/iscsiadm -k 0 2"
      ];
    };
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
    "default_hugepagesz=1G" "hugepagesz=1G" "hugepages=16"
  ];
}
