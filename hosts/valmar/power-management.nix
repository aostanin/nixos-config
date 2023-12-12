{
  config,
  lib,
  pkgs,
  ...
}: {
  boot.kernelParams = [
    "consoleblank=300"
    "pcie_aspm.policy=powersave"
    "snd_hda_intel.power_save=1"
  ];

  powerManagement = {
    scsiLinkPolicy = "med_power_with_dipm";
  };

  boot.kernel.sysctl = {
    # Match PowerTOP
    "vm.dirty_writeback_centisecs" = 1500;
  };

  # Match PowerTOP
  services.udev.extraRules = ''
    SUBSYSTEM=="pci", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
  '';
}
