{
  config,
  lib,
  pkgs,
  ...
}: let
  gpuSysfsPath = "/sys/devices/pci0000:00/0000:00:02.6/0000:09:00.0";
  gpuPowerManagementScript = pkgs.writeScriptBin "gpu-power-management" ''
    #!${pkgs.stdenv.shell}

    # Set host GPU to lowest power level
    echo "low" > ${gpuSysfsPath}/power_dpm_force_performance_level

    # The memory clock is locked to the highest power level so overwrite all power levels to match the lowest
    ${pkgs.upp}/bin/upp -p ${gpuSysfsPath}/pp_table set \
        MclkDependencyTable/1/Mclk=30000 MclkDependencyTable/1/Vddci=800 MclkDependencyTable/1/VddcInd=0 \
        MclkDependencyTable/2/Mclk=30000 MclkDependencyTable/2/Vddci=800 MclkDependencyTable/2/VddcInd=0 \
        --write
  '';
in {
  boot.kernelParams = [
    "amdgpu.ppfeaturemask=0xfff7ffff"
    "pcie_aspm.policy=powersave"
  ];

  powerManagement.powerUpCommands = ''
    ${gpuPowerManagementScript}/bin/gpu-power-management
  '';

  services.xserver.displayManager.setupCommands = "${gpuPowerManagementScript}/bin/gpu-power-management";

  services.udev.extraRules = ''
    # GPU lower power mode
    KERNEL=="card0", SUBSYSTEM=="drm", DRIVERS=="amdgpu", ATTR{device/power_dpm_force_performance_level}="low"
  '';
}
