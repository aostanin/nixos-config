{
  config,
  lib,
  pkgs,
  ...
}: let
  gpus = {
    amdRX570 = {
      driver = "amdgpu";
      pciIds = ["1002:67df" "1002:aaf0"];
      busId = "09:00.0";
    };
    nvidiaRTX2070Super = {
      driver = "nvidia";
      pciIds = ["10de:1e84" "10de:10f8" "10de:1ad8" "10de:1ad9"];
      busId = "01:00.0";
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
    extraModulePackages = with config.boot.kernelPackages; [
      vendor-reset
    ];
    initrd.kernelModules = [
      "vendor-reset"
    ];
    initrd.postDeviceCommands = ''
      echo device_specific > /sys/bus/pci/devices/0000:${gpus.amdRX570.busId}/reset_method
    '';
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
      macOS = {
        gpu = "amdRX570";
        enableHibernation = true;
      };
      ubuntu = {
        gpu = "amdRX570";
        enableHibernation = true;
      };
      valmar = {
        gpu = "amdRX570";
        enableHibernation = true;
      };
      win10-play = {
        gpu = "nvidiaRTX2070Super";
        enableHibernation = true;
        isolate = isolate8Core;
      };
      win10-play-amd = {
        gpu = "amdRX570";
        enableHibernation = true;
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
