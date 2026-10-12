# Platform-specific settings live here: everything in this file changes when
# valmar moves from the Ryzen 7700 / ASRock B850 to elena's MSI Z690 board.
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
    ./disko-config.nix
  ];

  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = [];
  # nct6775 drives the board's Nuvoton NCT6799D Super I/O (fans, voltages).
  boot.kernelModules = ["kvm-amd" "nct6775"];
  boot.extraModulePackages = [];

  # Partition layout, rpool, and fileSystems/swap come from disko-config.nix.
  disko.devices.disk.main.device = "/dev/disk/by-id/nvme-PS5027-E27T-1000G_BiCS6_250807139002760";
  disko.zfs.enable = true;

  # The iGPU drives the displays; the RTX 5060 Ti is for compute only.
  services.xserver.videoDrivers = ["modesetting" "nvidia"];
  hardware.nvidia = {
    # Blackwell is only supported by the open kernel modules.
    open = true;
    modesetting.enable = true;
  };

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
