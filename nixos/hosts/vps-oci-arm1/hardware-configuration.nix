{modulesPath, ...}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disko-config.nix
  ];

  boot.loader.grub = {
    configurationLimit = 3;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };

  boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "xen_blkfront"];
  boot.initrd.kernelModules = ["nvme"];

  disko.devices.disk.main.device = "/dev/disk/by-id/scsi-36045da7ba2ca4edc8f71bd98b69bb1cf";
}
