{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: let
  gpus = {
    nvidiaRTX2070Super = let
      docker = "${pkgs.docker}/bin/docker";
      jq = "${pkgs.jq}/bin/jq";
      setGpuLedColor = color: "${pkgs.openrgb}/bin/openrgb --noautoconnect -d 'RTX 2070 Super' -m direct -c ${color}";
      getNvidiaContainers = "${docker} inspect $(${docker} ps -aq) | ${jq} -r '.[] | select(any(.HostConfig.DeviceRequests[]?; contains({\"Driver\": \"nvidia\"}))) | .Id' |  xargs";
    in {
      driver = "nvidia";
      pciIds = ["10de:1e84" "10de:10f8" "10de:1ad8" "10de:1ad9"];
      busId = "01:00.0";
      preDetachCommands = ''
        ${docker} stop $(${getNvidiaContainers})
        ${setGpuLedColor "FF5555"}
      '';
      postAttachCommands = ''
        # Disable LED
        ${setGpuLedColor "000000"}
        ${docker} start $(${getNvidiaContainers})
      '';
    };
  };
  usbControllerIds = [
    "1912:0014" # Renesas Technology Corp. uPD720201
    "1b73:1100" # Fresco Logic FL1100
  ];
  vfioPciIds = usbControllerIds;
in {
  boot = {
    kernelParams = [
      "vfio-pci.ids=${lib.concatStringsSep "," vfioPciIds}"
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