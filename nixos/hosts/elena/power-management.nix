{
  lib,
  pkgs,
  ...
}: let
  drives = [
    "/dev/disk/by-id/ata-TOSHIBA_MN07ACA12T_80U0A007FEQG"
    "/dev/disk/by-id/ata-TOSHIBA_MN07ACA12T_9010A00BFEQG"
    "/dev/disk/by-id/ata-TOSHIBA_MN07ACA12T_Y240A03MFEQG"
    "/dev/disk/by-id/ata-TOSHIBA_MN07ACA12T_Y240A07LFEQG"
    "/dev/disk/by-id/ata-WDC_WD120EMFZ-11A6JA0_9JHA5RKT"
    "/dev/disk/by-id/ata-WDC_WD120EMFZ-11A6JA0_9RG1G3RC"
  ];
in {
  boot.kernelParams = [
    "pcie_aspm.policy=powersupersave"
    "snd_hda_intel.power_save=1"
    "nmi_watchdog=0" # Match PowerTOP
  ];

  powerManagement = {
    # One WD drive has read/write errors with anything other than max_performance
    scsiLinkPolicy = "max_performance";
  };

  boot.kernel.sysctl = {
    # Match PowerTOP
    "vm.dirty_writeback_centisecs" = 1500;
  };

  # Match PowerTOP
  services.udev.extraRules = ''
    # Disable power management for Intel I225-V as it causes issues
    SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x15f3", ATTR{power/control}="on", GOTO="pci_pm_end"
    SUBSYSTEM=="pci", ATTR{power/control}="auto"
    LABEL="pci_pm_end"
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
  '';

  # WD drives aren't going to sleep with just the standby timeout set
  systemd.services."hd-idle" = {
    description = "hd-idle - spin down idle hard disks";
    after = ["suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target"];
    serviceConfig = {
      Restart = "on-failure";
      Type = "simple";
      ExecStart = "${lib.getExe' pkgs.hd-idle "hd-idle"} -i 0 ${lib.concatStringsSep " " (map (drive: "-a ${drive} -i 900") drives)}";
    };
    wantedBy = ["multi-user.target"];
  };
}
