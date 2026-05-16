{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: let
  gpus = {
    nvidiaRTX2070Super = let
      podman = lib.getExe pkgs.podman;
      jq = lib.getExe pkgs.jq;
      fuser = lib.getExe' pkgs.psmisc "fuser";
      setGpuLedColor = color: "${lib.getExe pkgs.openrgb} --noautoconnect -d 'RTX 2070 Super' -m direct -c ${color}";
      keepUnits = "nvidia-persistenced|libvirtd|user@[0-9]+";
      stateFile = "/tmp/nvidia-services";
    in {
      driver = "nvidia";
      pciIds = ["10de:1e84" "10de:10f8" "10de:1ad8" "10de:1ad9"];
      busId = "01:00.0";
      powerManagementCommands = ''
        # Lowers idle from ~13 W to ~6 W. Otherwise the GPU continues displaying the last image.
        ${lib.getExe' pkgs.linuxPackages.nvidia_x11.bin "nvidia-smi"} --gpu-reset
      '';
      preDetachCommands = ''
        {
          for p in $(${fuser} /dev/nvidia* 2>/dev/null | tr -s ' ' '\n' | grep -E '^[0-9]+$'); do
            grep -oE '[^/]+\.service' /proc/"$p"/cgroup 2>/dev/null | tail -1
          done
          ids=$(${podman} ps -q 2>/dev/null) || ids=""
          if [ -n "$ids" ]; then
            ${podman} inspect $ids 2>/dev/null \
              | ${jq} -r '.[] | select(any(.HostConfig.Devices[]?; .PathOnHost == "/dev/nvidia0")) | "podman-\(.Name).service"'
          fi
        } | sort -u | grep -vE '^(${keepUnits})\.service$' > ${stateFile} || true

        units="$(cat ${stateFile} 2>/dev/null || true)"
        if [ -n "$units" ]; then
          echo "vfio: stopping GPU services before detach: $units" >&2
          systemctl stop $units
        fi

        ${setGpuLedColor "FF4444"} || true
      '';
      postAttachCommands = ''
        ${setGpuLedColor "000000"} || true
        systemctl restart nvidia-container-toolkit-cdi-generator.service || true

        if [ -s ${stateFile} ]; then
          units="$(cat ${stateFile})"
          echo "vfio: restarting GPU services after attach: $units" >&2
          systemctl start $units || true
        fi
        rm -f ${stateFile}
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
      "pci=realloc=off" # Prevent PCI BAR reallocation - fixes ReBAR + VFIO conflict
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
      win10-play = {
        gpu = "nvidiaRTX2070Super";
        enableHibernation = true;
        isolate = isolate14Thread;
      };
    };
  };
}
