{
  config,
  lib,
  pkgs,
  ...
}: let
  drives = map (id: "/dev/disk/by-id/${id}") (import ./drives.nix);
in {
  boot = {
    kernelParams = [
      "pcie_aspm.policy=powersupersave"
      "snd_hda_intel.power_save=1"
    ];
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
    SUBSYSTEM=="pci", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
  '';

  # 150W instead of 215W costs the 9B ~6% decode for ~60W less. Undervolt
  # (core +125, capped at 1800 MHz): decode +3% and prefill at 16% less power,
  # soak-tested with greedy output identical to stock. With core +150, a 1700 MHz
  # cap or a memory offset changed the output.
  systemd.services.nvidia-tune = {
    description = "Tune NVIDIA GPU clocks";
    wantedBy = ["multi-user.target"];
    serviceConfig = let
      nvidiaSmi = lib.getExe' config.hardware.nvidia.package.bin "nvidia-smi";
      nvidiaOc = lib.getExe pkgs.nvidia_oc;
    in {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = [
        "${nvidiaSmi} -pm 1"
        "${nvidiaSmi} -pl 150"
        "${nvidiaSmi} -lgc 210,1800"
        "${nvidiaOc} set --index 0 --freq-offset 125"
      ];
    };
  };

  # WD drives aren't going to sleep with just the standby timeout set
  systemd.services."hd-idle" = {
    # Spin-up through the SAS2008 outlasts the SCSI EH timeout and faulted a tank
    # disk. Re-enable after the ASM1166 swap.
    enable = false;
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
