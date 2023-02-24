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
  boot.kernelParams = [
    "pcie_aspm.policy=powersave"
  ];

  powerManagement = {
    scsiLinkPolicy = "med_power_with_dipm";
    powerUpCommands = ''
      ${pkgs.hdparm}/bin/hdparm -B 1 -S 120 ${lib.concatStringsSep " " drives}
    '';
  };

  systemd.services."hd-idle" = {
    description = "hd-idle - spin down idle hard disks";
    after = ["suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target"];
    serviceConfig = {
      Restart = "on-failure";
      Type = "simple";
      ExecStart = "${pkgs.hd-idle}/bin/hd-idle -i 0 ${lib.concatStringsSep " " (map (drive: "-a ${drive} -i 600") drives)}";
    };
    wantedBy = ["multi-user.target"];
  };
}
