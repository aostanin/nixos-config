{...}: {
  boot = {
    kernelParams = [
      "pcie_aspm.policy=powersupersave"
      "nmi_watchdog=0"
    ];
    kernel.sysctl."vm.dirty_writeback_centisecs" = 1500;
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="pci", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
  '';
}
