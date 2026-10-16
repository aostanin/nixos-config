{
  config,
  lib,
  pkgs,
  inputs,
  modulesPath,
  ...
}: {
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
    "${inputs.nixos-hardware}/common/cpu/amd/pstate.nix"
    "${inputs.nixos-hardware}/common/gpu/amd"
  ];

  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "mpt3sas" "usbhid" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = [];
  # nct6775 drives the board's Nuvoton NCT6799D Super I/O (fans, voltages).
  boot.kernelModules = ["kvm-amd" "nct6775"];
  boot.extraModulePackages = [];

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6FE7-AC4D";
    fsType = "vfat";
    options = ["umask=0077"];
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
      device = "/dev/disk/by-uuid/334764a1-5ff9-4cb2-8a63-132f99c3410d";
      options = ["nofail"];
    }
  ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
