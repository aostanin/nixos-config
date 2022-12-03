{
  config,
  pkgs,
  ...
}: let
  usbPciIds = "1b73:1100";
in {
  services.persistent-evdev = {
    enable = true;
    devices = {
      persist-keyboard0 = "usb-04d9_USB_Keyboard-event-kbd";
      persist-mouse0 = "usb-SINOWEALTH_Wired_Gaming_Mouse-event-mouse";
    };
  };

  services.vfio = {
    enable = true;
    cpuType = "amd";
    enableLookingGlass = true;
    qemu = {
      user = "aostanin";
      devices = [
        "/dev/input/by-id/uinput-persist-keyboard0"
        "/dev/input/by-id/uinput-persist-mouse0"
      ];
    };
    # gpu = {
    #   # RX 570
    #   driver = "amdgpu";
    #   pciIds = ["1458:22f7" "1458:aaf0"];
    #   busId = "0a:00.0";
    # };
    gpu = {
      # RTX 2070 Super
      driver = "nvidia";
      pciIds = ["10de:1e84" "10de:10f8" "10de:1ad8" "10de:1ad9"];
      busId = "0b:00.0";
    };
    vms = let
      isolate = {
        enable = true;
        dropCaches = true;
        compactMemory = true;
        isolateCpus = true;
        allCpus = ["0-23"];
        hostCpus = ["0-5" "12-17"];
        guestCpus = ["0-1" "12-13" "6-11" "18-23"];
      };
    in {
      win10-play = {
        useGpu = true;
        enableHibernation = true;
        isolate = isolate;
      };
      win10-zwift = {
        useGpu = true;
        enableHibernation = true;
        isolate = isolate;
      };
    };
  };
}
