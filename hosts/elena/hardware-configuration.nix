# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = ["${modulesPath}/installer/scan/not-detected.nix"];

  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "mpt3sas" "usbhid" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel" "i2c-dev"];
  boot.extraModulePackages = [];

  fileSystems."/boot1" = {
    device = "/dev/disk/by-uuid/3A2B-B155";
    fsType = "vfat";
    options = ["nofail"];
  };

  fileSystems."/boot2" = {
    device = "/dev/disk/by-uuid/3B7B-1CCB";
    fsType = "vfat";
    options = ["nofail"];
  };

  fileSystems."/" = {
    device = "rpool/root/nixos";
    fsType = "zfs";
    options = ["zfsutil" "noatime" "X-mount.mkdir"];
  };

  fileSystems."/nix" = {
    device = "rpool/root/nix";
    fsType = "zfs";
    options = ["zfsutil" "noatime" "X-mount.mkdir"];
  };

  swapDevices = [
    {
      device = "/dev/disk/by-uuid/b0fc0976-3801-4d29-8c89-14767c3d75a7";
      options = ["nofail"];
    }
    {
      device = "/dev/disk/by-uuid/753cf088-a1cd-4f6e-984c-b34cd3f36f4a";
      options = ["nofail"];
    }
  ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
