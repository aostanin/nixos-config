{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: let
  # JRAINBOW1 is the only ARGB header with a strip. It starts with zero LEDs, so
  # it is sized in the same block as its color.
  setLedColor = color: "${lib.getExe pkgs.openrgb} --noautoconnect --device 'PRO Z690-A' --zone 1 --size 30 --mode static --color ${color}";

  gpus = {
    nvidiaRTX5060Ti = {
      driver = "nvidia";
      pciIds = ["10de:2d04" "10de:22eb"];
      busId = "01:00.0";
      preDetachCommands = ''
        ${setLedColor "FF4444"} || true
      '';
      postAttachCommands = ''
        ${setLedColor "000000"} || true
      '';
    };
  };
  usbControllerIds = [
    "1912:0014" # Renesas Technology Corp. uPD720201
  ];
  vfioPciIds = usbControllerIds;
in {
  boot = {
    kernelParams = lib.mkAfter [
      "vfio-pci.ids=${lib.concatStringsSep "," vfioPciIds}"
      "pci=realloc=off" # Prevent PCI BAR reallocation - fixes ReBAR + VFIO conflict
      # DRM fbdev supports prevents unbinding the nvidia driver
      # NOTE: We need lib.mkAfter here as the NixOS NVIDIA module enables it
      "nvidia-drm.fbdev=0"
    ];
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
    gpuHostUnits = [
      "llama-swap.service"
      "nvidia-container-toolkit-cdi-generator.service"
    ];
    vms = let
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
      win10-play = {
        gpu = "nvidiaRTX5060Ti";
        enableHibernation = true;
        isolate = isolate14Thread;
      };
    };
  };
}
