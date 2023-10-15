{
  config,
  lib,
  pkgs,
  ...
}: let
  secrets = import ../../secrets;
  gpus = {
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
    keyboard = "/dev/input/by-id/usb-Kingsis_Corporation_VAXEE_Mouse-event-mouse";
  };
  vfioPciIds = usbControllerIds;
in {
  boot = {
    kernelParams = [
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

  localModules.vfio = {
    enable = true;
    cpuType = "intel";
    lookingGlass = {
      enable = true;
      enableKvmfr = true;
      kvmfrSizes = [64];
      kvmfrUser = secrets.user.username;
    };
    gpus = gpus;
    qemu.devices = [
      "/dev/input/by-id/virtual-keyboard-1"
      "/dev/input/by-id/virtual-mouse-1"
      "/dev/input/by-id/virtual-keyboard-2"
      "/dev/input/by-id/virtual-mouse-2"
    ];
    vms = let
      isolate8ThreadFirst = {
        enable = true;
        dropCaches = false;
        compactMemory = false;
        isolateCpus = true;
        allCpus = ["0-23"];
        hostCpus = ["8-15" "16-23"];
        guestCpus = ["16-17" "0-7"];
      };
      isolate8ThreadSecond = {
        enable = true;
        dropCaches = false;
        compactMemory = false;
        isolateCpus = true;
        allCpus = ["0-23"];
        hostCpus = ["0-7" "16-23"];
        guestCpus = ["16-17" "8-15"];
      };
      isolate16Thread = {
        enable = true;
        dropCaches = false;
        compactMemory = false;
        isolateCpus = true;
        allCpus = ["0-23"];
        hostCpus = ["16-23"];
        guestCpus = ["16-17" "0-15"];
      };
    in {
      win10-play = {
        gpu = "nvidiaRTX2070Super";
        enableHibernation = true;
        isolate =
          isolate16Thread
          // {
            setPerformanceGovernor = true;
          };
      };
    };
  };
}
