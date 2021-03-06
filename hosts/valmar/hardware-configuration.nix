# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ "${modulesPath}/installer/scan/not-detected.nix" ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "rpool/root/nixos";
      fsType = "zfs";
      options = [ "noatime" "nodiratime" ];
    };

  fileSystems."/nix" =
    {
      device = "rpool/root/nix";
      fsType = "zfs";
      options = [ "noatime" "nodiratime" ];
    };

  fileSystems."/home" =
    {
      device = "rpool/home";
      fsType = "zfs";
      options = [ "noatime" "nodiratime" ];
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/1FA6-DE5C";
      fsType = "vfat";
    };

  fileSystems."/var/lib/docker" =
    {
      device = "rpool/virtualization/docker";
      fsType = "zfs";
      options = [ "noatime" "nodiratime" ];
    };

  fileSystems."/var/lib/libvirt" =
    {
      device = "rpool/virtualization/libvirt";
      fsType = "zfs";
      options = [ "noatime" "nodiratime" ];
    };

  fileSystems."/var/lib/libvirt/images" =
    {
      device = "rpool/virtualization/libvirt/images";
      fsType = "zfs";
      options = [ "noatime" "nodiratime" ];
    };

  swapDevices =
    [
      { device = "/dev/disk/by-uuid/46a8575f-76a1-4f99-87fa-8e56aa7dc0c4"; }
    ];

  nix.maxJobs = lib.mkDefault 24;
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
