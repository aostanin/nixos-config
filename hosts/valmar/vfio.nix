{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: let
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
    wantedBy = ["multi-user.target"];
    # If rkvm starts first then evsieve doesn't seem to work.
    # TODO: Limit rkvm input devices to virtual-*-1: https://github.com/htrefil/rkvm/pull/55
    before = ["rkvm-server.service"];
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
      isolate6ThreadFirst = {
        enable = true;
        dropCaches = false;
        compactMemory = false;
        isolateCpus = true;
        allCpus = ["0-23"];
        hostCpus = ["0-1" "8-15" "16-23"];
        guestCpus = ["0-1" "2-7"];
      };
      isolate8ThreadSecond = {
        enable = true;
        dropCaches = false;
        compactMemory = false;
        isolateCpus = true;
        allCpus = ["0-23"];
        hostCpus = ["0-7" "16-23"];
        guestCpus = ["0-1" "8-15"];
      };
      isolate14Thread = {
        enable = true;
        dropCaches = false;
        compactMemory = false;
        isolateCpus = true;
        allCpus = ["0-23"];
        hostCpus = ["0-1" "16-23"];
        guestCpus = ["0-1" "2-15"];
      };
    in {
      playground = {
        gpu = "nvidiaRTX2070Super";
        enableHibernation = true;
        isolate = isolate14Thread;
      };
      win10-play = {
        gpu = "nvidiaRTX2070Super";
        enableHibernation = true;
        isolate =
          isolate14Thread
          // {
            setPerformanceGovernor = true;
          };
      };
    };
  };
}
