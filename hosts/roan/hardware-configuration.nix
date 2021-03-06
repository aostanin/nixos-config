# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ "${modulesPath}/installer/scan/not-detected.nix" ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
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
      device = "/dev/disk/by-uuid/0CB9-5273";
      fsType = "vfat";
    };

  fileSystems."/var/lib/docker" =
    {
      device = "rpool/docker";
      fsType = "zfs";
      options = [ "noatime" "nodiratime" ];
    };

  swapDevices =
    [
      { device = "/dev/disk/by-uuid/c9347241-59a5-488a-aaf3-de144bae07a1"; }
    ];

  nix.maxJobs = lib.mkDefault 4;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
