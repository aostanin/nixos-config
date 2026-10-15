{...}: {
  boot = {
    kernelParams = [
      "pcie_aspm.policy=powersupersave"
      "snd_hda_intel.power_save=1"
    ];
    kernel.sysctl."vm.dirty_writeback_centisecs" = 1500;
  };

  services.udev.extraRules = ''
    # Disable power management for Intel I225-V as it causes issues
    SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x15f3", ATTR{power/control}="on", GOTO="pci_pm_end"
    SUBSYSTEM=="pci", ATTR{power/control}="auto"
    LABEL="pci_pm_end"
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
  '';
}
