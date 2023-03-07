{
  config,
  lib,
  pkgs,
  ...
}: let
  gpus = {
    amdRX570 = rec {
      driver = "amdgpu";
      pciIds = ["1002:67df" "1002:aaf0"];
      busId = "09:00.0";
      powerManagementCommands = ''
        # Set host GPU to lowest power level
        echo "low" > /sys/bus/pci/devices/0000:${busId}/power_dpm_force_performance_level

        # The memory clock is locked to the highest power level when multiple monitors are connected.
        # Force overwrite all power levels to match the lowest.
        # Lowers idle from ~22 W to ~6 W
        ${pkgs.upp}/bin/upp -p /sys/bus/pci/devices/0000:${busId}/pp_table set \
            MclkDependencyTable/1/Mclk=30000 MclkDependencyTable/1/Vddci=800 MclkDependencyTable/1/VddcInd=0 \
            MclkDependencyTable/2/Mclk=30000 MclkDependencyTable/2/Vddci=800 MclkDependencyTable/2/VddcInd=0 \
            --write
      '';
    };
    nvidiaRTX2070Super = {
      driver = "nvidia";
      pciIds = ["10de:1e84" "10de:10f8" "10de:1ad8" "10de:1ad9"];
      busId = "01:00.0";
      powerManagementCommands = ''
        # Lowers idle from ~13 W to ~6 W
        ${pkgs.linuxPackages.nvidia_x11.bin}/bin/nvidia-smi --gpu-reset
      '';
    };
  };
  usbControllerIds = [
    "1912:0014" # Renesas Technology Corp. uPD720201
    "1b73:1100" # Fresco Logic FL1100
  ];
  peripherals = {
    mouse = "/dev/input/by-id/usb-04d9_USB_Keyboard-event-kbd";
    keyboard = "/dev/input/by-id/usb-SINOWEALTH_Wired_Gaming_Mouse-event-mouse";
  };
  vfioPciIds = usbControllerIds;
in {
  boot = {
    initrd.kernelModules = [
      # Load amdgpu for power management commands to work
      "amdgpu"
    ];
    kernelParams = [
      "amdgpu.ppfeaturemask=0xfff7ffff"
      "vfio-pci.ids=${lib.concatStringsSep "," vfioPciIds}"
    ];
  };

  systemd.services."evsieve" = {
    serviceConfig = {
      Restart = "on-failure";
      Type = "notify";
      ExecStart = ''
        ${pkgs.evsieve}/bin/evsieve \
          --input ${peripherals.keyboard} domain=kb grab=auto persist=reopen \
          --input ${peripherals.mouse} domain=ms grab=auto persist=reopen \
          --hook   key:scrolllock toggle   \
          --toggle @kb @vkb1 @vkb2  \
          --toggle @ms @vms1 @vms2  \
          --output @vkb1 create-link=/dev/input/by-id/virtual-keyboard-1   \
          --output @vms1 create-link=/dev/input/by-id/virtual-mouse-1 \
          --output @vkb2 create-link=/dev/input/by-id/virtual-keyboard-2 \
          --output @vms2 create-link=/dev/input/by-id/virtual-mouse-2
      '';
    };
    wantedBy = ["multi-user.target"];
  };

  services.vfio = {
    enable = true;
    cpuType = "intel";
    enableLookingGlass = true;
    gpus = gpus;
    qemu.devices = [
      "/dev/input/by-id/virtual-keyboard-1"
      "/dev/input/by-id/virtual-mouse-1"
      "/dev/input/by-id/virtual-keyboard-2"
      "/dev/input/by-id/virtual-mouse-2"
    ];
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
      macOS-amd = {
        gpu = "amdRX570";
        enableHibernation = true;
        isolate = isolate8Core;
      };
      ubuntu-amd = {
        gpu = "amdRX570";
        enableHibernation = true;
        isolate = isolate8Core;
      };
      valmar-amd = {
        gpu = "amdRX570";
        enableHibernation = true;
        isolate = isolate8Core;
      };
      valmar-nvidia = {
        gpu = "nvidiaRTX2070Super";
        enableHibernation = true;
        isolate = isolate8Core;
      };
      win10-play-amd = {
        gpu = "amdRX570";
        enableHibernation = true;
        isolate = isolate8Core;
      };
      win10-play-nvidia = {
        gpu = "nvidiaRTX2070Super";
        enableHibernation = true;
        isolate = isolate8Core;
      };
      win10-work = {
        enableHibernation = true;
      };
      win10-work-intel = {
        enableHibernation = true;
      };
    };
  };
}
