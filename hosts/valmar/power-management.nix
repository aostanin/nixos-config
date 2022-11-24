{
  config,
  lib,
  pkgs,
  ...
}: let
  gpuSysfsPath = "/sys/devices/pci0000:00/0000:00:03.1/0000:0a:00.0";
  backupDrives = [
    "/dev/disk/by-id/ata-Hitachi_HDS5C3030ALA630_MJ1311YNG052SA"
    "/dev/disk/by-id/ata-Hitachi_HDS5C3030ALA630_MJ1311YNG2TT6A"
    "/dev/disk/by-id/ata-Hitachi_HDS5C3030ALA630_MJ1311YNG2TTLA"
    "/dev/disk/by-id/ata-Hitachi_HDS5C3030ALA630_MJ1311YNG2TV0A"
  ];
in {
  boot.kernelParams = [
    "amdgpu.ppfeaturemask=0xfff7ffff"
  ];

  powerManagement.powerUpCommands = ''
    # Set host GPU to lowest power level
    echo "low" > ${gpuSysfsPath}/power_dpm_force_performance_level

    # The memory clock is locked to the highest power level so overwrite all power levels to match the lowest
    ${pkgs.upp}/bin/upp -p ${gpuSysfsPath}/pp_table set \
        MclkDependencyTable/1/Mclk=30000 MclkDependencyTable/1/Vddci=800 MclkDependencyTable/1/VddcInd=0 \
        MclkDependencyTable/2/Mclk=30000 MclkDependencyTable/2/Vddci=800 MclkDependencyTable/2/VddcInd=0 \
        --write

    # Calling hdparm brings the drives out of standby, so disable for now
    #${pkgs.hdparm}/bin/hdparm -B 1 -S 6 -y ${lib.concatStringsSep " " backupDrives}
  '';

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
