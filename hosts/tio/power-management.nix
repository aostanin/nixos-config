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
    powertop.enable = true;

    scsiLinkPolicy = "med_power_with_dipm";
  };
}
