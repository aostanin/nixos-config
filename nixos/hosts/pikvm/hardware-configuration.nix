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
    pkgs.runCommand "raspberrypifw-rpi4-only" {nativeBuildInputs = [pkgs.buildPackages.dtc];} ''
      src=${full}/share/raspberrypi/boot
      dst=$out/share/raspberrypi/boot
      mkdir -p $dst
      cp -r $src/overlays $dst/
      chmod u+w $dst/overlays
      dtc -@ -I dts -O dtb -o $dst/overlays/poe-hat-b-fan.dtbo ${./poe-hat-b-fan.dts}
      cp $src/bcm2711-*.dtb $src/start4*.elf $src/fixup4*.dat $src/bootcode.bin $dst/
    '';

  # Waveshare PoE HAT (B): OLED (kvmd-oled) and fan expander share i2c_arm.
  hardware.raspberry-pi.config.all = {
    base-dt-params.i2c_arm = {
      enable = true;
      value = "on";
    };
    dt-overlays.poe-hat-b-fan.enable = true;
  };
}
