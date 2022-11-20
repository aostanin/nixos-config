{
  config,
  lib,
  pkgs,
  ...
}: let
  backupDrives = [
    "/dev/disk/by-id/ata-Hitachi_HDS5C3030ALA630_MJ1311YNG052SA"
    "/dev/disk/by-id/ata-Hitachi_HDS5C3030ALA630_MJ1311YNG2TT6A"
    "/dev/disk/by-id/ata-Hitachi_HDS5C3030ALA630_MJ1311YNG2TV0A"
  ];
in {
  # TODO: Calling hdparm brings the drives out of standby
  # powerManagement.powerUpCommands = "${pkgs.hdparm}/bin/hdparm -B 1 -S 6 -y ${lib.concatStringsSep " " backupDrives}";

  systemd.services."hd-idle" = {
    description = "hd-idle - spin down idle hard disks";
    after = ["suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.hd-idle}/bin/hd-idle -i 0 ${lib.concatStringsSep " " (map (drive: "-a ${drive} -i 30") backupDrives)}";
    };
    wantedBy = ["multi-user.target"];
  };
}
