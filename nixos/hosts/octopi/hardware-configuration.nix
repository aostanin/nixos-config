{
  lib,
  pkgs,
  ...
}: {
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  fileSystems."/boot/firmware" = {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
    options = ["noatime" "nofail"];
  };

  boot.loader.raspberry-pi = {
    firmwarePackage = pkgs.runCommand "raspberrypifw-rpi3-only" {} ''
      src=${pkgs.raspberrypifw}/share/raspberrypi/boot
      dst=$out/share/raspberrypi/boot
      mkdir -p $dst
      cp $src/bcm2710-rpi-3-b.dtb $src/start.elf $src/fixup.dat $src/bootcode.bin $dst/
    '';
    ubootPackage = pkgs.ubootRaspberryPi3_64bit;
  };
  # U-Boot boots with the vendor DTB, but the kernel must get the generation's,
  # which carries the dwc2 overlay.
  boot.loader.generic-extlinux-compatible.useGenerationDeviceTree = lib.mkForce true;
}
