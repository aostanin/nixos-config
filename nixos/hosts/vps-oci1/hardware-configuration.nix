{modulesPath, ...}: {
  imports = [(modulesPath + "/profiles/qemu-guest.nix")];
  boot.loader.grub = {
    configurationLimit = 3;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/8DEA-BE31";
    fsType = "vfat";
  };
  boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi"];
  boot.initrd.kernelModules = ["nvme"];
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };
  swapDevices = [
    {
      device = "/var/swapfile";
      size = 2048;
    }
  ];
}
