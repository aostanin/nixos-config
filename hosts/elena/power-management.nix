{
  config,
  lib,
  pkgs,
  ...
}: {
  boot.kernelParams = [
    "pcie_aspm.policy=powersave"
  ];

  powerManagement = {
    scsiLinkPolicy = "med_power_with_dipm";
  };
}
