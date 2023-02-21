{
  config,
  lib,
  pkgs,
  ...
}: {
  boot = {
    kernelParams = [
      "i915.enable_fbc=1"
      "vfio-pci.ids=1912:0014,1b73:1100" # USB
    ];
  };

  services.vfio = let
    amdRX570 = {
      # RX 570
      driver = "amdgpu";
      pciIds = ["1458:22f7" "1458:aaf0"];
      busId = "09:00.0";
    };
    #nvidiaQuadroP400 = {
    #  # Quadro P400
    #  driver = "nvidia";
    #  pciIds = ["10de:1cb3" "10de:0fb9"];
    #  busId = "01:00.0";
    #};
    nvidiaRTX2070Super = {
      # RTX 2070 Super
      driver = "nvidia";
      pciIds = ["10de:1e84" "10de:10f8" "10de:1ad8" "10de:1ad9"];
      busId = "01:00.0";
    };
  in {
    enable = true;
    cpuType = "intel";
    enableLookingGlass = true;
    gpu = nvidiaRTX2070Super;
    vms = let
      isolate8Core = {
        enable = true;
        dropCaches = false;
        compactMemory = false;
        isolateCpus = true;
        allCpus = ["0-11"];
        hostCpus = ["0-3"];
        guestCpus = ["0-1" "4-11"];
      };
    in {
      valmar = {
        useGpu = false;
        enableHibernation = true;
      };
      win10-play = {
        useGpu = true;
        enableHibernation = true;
        isolate = isolate8Core;
      };
      win10-work = {
        useGpu = false;
        enableHibernation = true;
      };
      win10-work-intel = {
        useGpu = false;
        enableHibernation = true;
      };
    };
  };
}
