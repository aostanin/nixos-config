{
  config,
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
  boot = {
    kernelParams = [
      "pcie_aspm.policy=powersupersave"
      "snd_hda_intel.power_save=1"
    ];
    # For hardware monitoring
    extraModulePackages = [config.boot.kernelPackages.nct6687d];
    kernelModules = ["nct6687"];
  };

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

  # Memory +4000 (Afterburner +2000) and an undervolt (core +300, capped at
  # 2730 MHz): the 9B decodes 14% faster at 8% less power. Soak-tested with
  # greedy output identical to stock. The driver drops these on unbind, so
  # reapply whenever gpu-host.target starts.
  systemd.services.nvidia-tune = {
    description = "Tune NVIDIA GPU clocks";
    serviceConfig = let
      nvidiaSmi = lib.getExe' config.hardware.nvidia.package.bin "nvidia-smi";
      nvidiaOc = lib.getExe pkgs.nvidia_oc;
    in {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = [
        "${nvidiaSmi} -pm 1"
        "${nvidiaSmi} -lgc 210,2730"
        "${nvidiaOc} set --index 0 --mem-offset 4000"
        "${nvidiaOc} set --index 0 --freq-offset 300"
      ];
    };
  };
  localModules.vfio.gpuHostUnits = ["nvidia-tune.service"];

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
