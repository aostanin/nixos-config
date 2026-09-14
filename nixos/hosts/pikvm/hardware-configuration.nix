{
  pkgs,
  nixos-raspberrypi,
  ...
}: {
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  fileSystems."/boot/firmware" = {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
    options = ["noatime" "nofail"];
  };

  boot.loader.raspberry-pi.firmwarePackage = let
    full = nixos-raspberrypi.packages.${pkgs.stdenv.hostPlatform.system}.raspberrypifw;
  in
    pkgs.runCommand "raspberrypifw-rpi4-only" {} ''
      src=${full}/share/raspberrypi/boot
      dst=$out/share/raspberrypi/boot
      mkdir -p $dst
      cp -r $src/overlays $dst/
      cp $src/bcm2711-*.dtb $src/start4*.elf $src/fixup4*.dat $src/bootcode.bin $dst/
    '';
}
