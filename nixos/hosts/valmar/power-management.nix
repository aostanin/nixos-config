{...}: {
  boot = {
    kernelParams = ["pcie_aspm.policy=powersupersave"];
    kernel.sysctl."vm.dirty_writeback_centisecs" = 1500;
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="pci", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
    # r8169 leaves ASPM off by default; L1 measured stable here.
    ACTION=="bind", SUBSYSTEM=="pci", DRIVER=="r8169", ATTR{link/l1_aspm}="1"
  '';
}
