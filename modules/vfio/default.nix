{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.localModules.vfio;

  libvirt = config.virtualisation.libvirtd.package;
  nvidiaBin = pkgs.linuxPackages.nvidia_x11.bin;

  lookingGlassSubmodule = lib.types.submodule {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = true;
        description = ''
          Enable support for looking-glass-client.
        '';
      };

      enableShm = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = true;
        description = ''
          Create the /dev/shm/looking-glass shm file.
        '';
      };

      enableKvmfr = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = true;
        description = ''
          Load the kvmfr kernel module.
        '';
      };

      kvmfrSizes = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = [];
        example = [64];
        description = ''
          List of static kvmfr devices to create in MiB.
        '';
      };

      kvmfrUser = lib.mkOption {
        type = lib.types.str;
        default = "root";
        example = "bob";
        description = ''
          The user who owns the kvmfr device.
        '';
      };
    };
  };

  qemuSubmodule = lib.types.submodule {
    options = {
      user = lib.mkOption {
        type = lib.types.str;
        default = "root";
        example = "bob";
        description = ''
          The user to run qemu as.
        '';
      };

      devices = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = [
          "/dev/input/by-id/usb-04d9_USB_Keyboard-event-kbd"
          "/dev/input/by-id/usb-SINOWEALTH_Wired_Gaming_Mouse-event-mouse"
        ];
        description = ''
          Additional devices that qemu has access to. Useful for evdev passthrough.
        '';
      };
    };
  };

  gpuSubmodule = lib.types.submodule {
    options = {
      driver = lib.mkOption {
        type = lib.types.str;
        example = "nvidia";
        description = ''
          Currently only "nvidia" is supported.
        '';
      };

      pciIds = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        example = ["1458:22f7" "1458:aaf0"];
        description = ''
          The PCI ids of the GPU devices.
        '';
      };

      busId = lib.mkOption {
        type = lib.types.str;
        example = "0a:00.0";
        description = ''
          The bus id in the same format as lspci.
        '';
      };

      preDetachCommands = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Commands to run before detaching the card.
        '';
      };

      postAttachCommands = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Commands to run after attaching the card.
        '';
      };

      powerManagementCommands = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Commands to run to put the card in a low power state.
        '';
      };
    };
  };

  isolateSubmodule = lib.types.submodule {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = true;
        description = ''
          Run vfio-isolate before starting the VM.
        '';
      };

      dropCaches = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = true;
        description = ''
          Drop caches before starting the VM.
        '';
      };

      compactMemory = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = true;
        description = ''
          Compact memory before starting the VM.
        '';
      };

      isolateCpus = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = true;
        description = ''
          Isolate CPUs before starting the VM.
        '';
      };

      allCpus = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = ["0-23"];
        description = ''
          List of ranges for all host CPUs.
        '';
      };

      hostCpus = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = ["0-5" "12-17"];
        description = ''
          List of ranges for the remaining host CPUs.
        '';
      };

      guestCpus = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = ["0-1" "12-13" "6-11" "18-23"];
        description = ''
          List of ranges for the guest CPUs.
        '';
      };
    };
  };

  vmSubmodule = lib.types.submodule {
    options = {
      gpu = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "amdRX570";
        description = ''
          Which GPU to use for this VM.
        '';
      };

      enableHibernation = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = true;
        description = ''
          Hibernate the VM when the host shuts down or goes to sleep.
        '';
      };

      isolate = lib.mkOption {
        type = isolateSubmodule;
        default = {};
        description = ''
          Settings for vfio-isolate.
        '';
      };

      startCommands = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Commands to run before the VM starts.
        '';
      };

      endCommands = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Commands to run after the VM ends.
        '';
      };
    };
  };

  # https://github.com/PassthroughPOST/VFIO-Tools/blob/master/libvirt_hooks/qemu
  qemuHook = pkgs.writeShellScript "qemu" ''
    # Author: Sebastiaan Meijer (sebastiaan@passthroughpo.st)
    #
    # Copy this file to /etc/libvirt/hooks, make sure it's called "qemu".
    # After this file is installed, restart libvirt.
    # From now on, you can easily add per-guest qemu hooks.
    # Add your hooks in /etc/libvirt/hooks/qemu.d/vm_name/hook_name/state_name.
    # For a list of available hooks, please refer to https://www.libvirt.org/hooks.html
    #

    GUEST_NAME="$1"
    HOOK_NAME="$2"
    STATE_NAME="$3"
    MISC="''${@:4}"

    BASEDIR="/etc/libvirt/hooks"

    HOOKPATH="$BASEDIR/qemu.d/$GUEST_NAME/$HOOK_NAME/$STATE_NAME"

    set -e # If a script exits with an error, we should as well.

    # check if it's a non-empty executable file
    if [ -f "$HOOKPATH" ] && [ -s "$HOOKPATH"] && [ -x "$HOOKPATH" ]; then
        eval \"$HOOKPATH\" "$@"
    elif [ -d "$HOOKPATH" ]; then
        while read file; do
            # check for null string
            if [ ! -z "$file" ]; then
              eval \"$file\" "$@"
            fi
        done <<< "$(find -L "$HOOKPATH" -maxdepth 1 -type f -executable -print;)"
    fi
  '';

  lookingGlassClient = pkgs.looking-glass-client;

  # https://gist.github.com/Roliga/928cd44440f4df74e796e4e1315034bf
  hibernateScript = pkgs.writeScriptBin "hibernate-vm" ''
    #!${pkgs.stdenv.shell}

    #
    # Usage: hibernate-vm NAME
    #
    # Hibernates the VM specified in NAME and waits for it to finish shutting down
    #

    if ${lib.getExe' libvirt "virsh"} dompmsuspend "$1" disk; then
      echo "Waiting for domain to finish shutting down.." >&2
      while ! [ "$(${lib.getExe' libvirt "virsh"} domstate "$1")" == 'shut off' ]; do
        sleep 1
      done
      echo "Domain finished shutting down" >&2
    fi
  '';

  gpuDetachScript = gpu:
    pkgs.writeScriptBin "vfio-gpu-detach"
    (
      if (gpu.driver == "amdgpu")
      then ''
        #!${pkgs.stdenv.shell}
        set -e

        ${gpu.preDetachCommands}

        if [ -d /sys/bus/pci/drivers/amdgpu/0000:${gpu.busId} ]; then
          echo 0000:${gpu.busId} > /sys/bus/pci/drivers/amdgpu/unbind
        fi

        # Binding to amdgpu resizes the BAR from 256MB to 4GB (on RX 570). This causes Windows
        # guests to fail initializing DirectX and macOS guests to hang during boot.
        # Setting the BAR size back to 256MB before starting the VM fixes these issues.
        echo 8 > /sys/bus/pci/devices/0000:${gpu.busId}/resource0_resize

        if [ $(basename $(readlink /sys/bus/pci/devices/0000:${gpu.busId}/driver)) != "vfio-pci" ]; then
          ${lib.getExe' libvirt "virsh"} nodedev-detach pci_0000_${(lib.replaceStrings [":" "."] ["_" "_"] gpu.busId)}
        fi
      ''
      else if (gpu.driver == "nvidia")
      then ''
        #!${pkgs.stdenv.shell}
        set -e

        ${gpu.preDetachCommands}

        systemctl stop nvidia-persistenced.service

        # Avoid in use error when modeset is enabled
        modprobe -r nvidia_uvm
        modprobe -r nvidia_drm
        modprobe -r nvidia_modeset
        modprobe -r nvidia
        modprobe -r i2c_nvidia_gpu

        # Avoid detaching the GPU if it's in use
        # TODO: Kill processes with --kill?
        ${lib.getExe' pkgs.psmisc "fuser"} /dev/nvidia0 && exit 1

        if [ $(basename $(readlink /sys/bus/pci/devices/0000:${gpu.busId}/driver)) != "vfio-pci" ]; then
          ${lib.getExe' libvirt "virsh"} nodedev-detach pci_0000_${(lib.replaceStrings [":" "."] ["_" "_"] gpu.busId)}
        fi
      ''
      else throw "Unsupported gpu driver ${gpu.driver}"
    );

  gpuAttachScript = gpu:
    pkgs.writeScriptBin "vfio-gpu-attach"
    (
      if (gpu.driver == "amdgpu")
      then ''
        #!${pkgs.stdenv.shell}
        set -e

        if [ $(basename $(readlink /sys/bus/pci/devices/0000:${gpu.busId}/driver)) == "vfio-pci" ]; then
          ${lib.getExe' libvirt "virsh"} nodedev-reattach pci_0000_${(lib.replaceStrings [":" "."] ["_" "_"] gpu.busId)}
        fi

        ${gpu.postAttachCommands}
      ''
      else if (gpu.driver == "nvidia")
      then ''
        #!${pkgs.stdenv.shell}
        set -e

        if [ $(basename $(readlink /sys/bus/pci/devices/0000:${gpu.busId}/driver)) == "vfio-pci" ]; then
          ${lib.getExe' libvirt "virsh"} nodedev-reattach pci_0000_${(lib.replaceStrings [":" "."] ["_" "_"] gpu.busId)}
        fi

        modprobe i2c_nvidia_gpu
        modprobe nvidia
        modprobe nvidia_modeset
        modprobe nvidia_drm
        modprobe nvidia_uvm

        systemctl start nvidia-persistenced.service

        ${gpu.postAttachCommands}
      ''
      else throw "Unsupported gpu driver ${gpu.driver}"
    );
  gpuAttachAllScript =
    pkgs.writeScriptBin "vfio-gpus-attach"
    (lib.concatStringsSep "\n"
      (lib.mapAttrsToList (gpuName: gpu: (lib.getExe (gpuAttachScript gpu))) cfg.gpus));
  gpuDetachAllScript =
    pkgs.writeScriptBin "vfio-gpus-detach"
    (lib.concatStringsSep "\n"
      (lib.mapAttrsToList (gpuName: gpu: (lib.getExe (gpuDetachScript gpu))) cfg.gpus));
in {
  options.localModules.vfio = {
    enable = lib.mkEnableOption "vfio";

    cpuType = lib.mkOption {
      type = lib.types.str;
      example = "amd";
      description = ''
        The host CPU type, either "intel" or "amd".
      '';
    };

    lookingGlass = lib.mkOption {
      type = lookingGlassSubmodule;
      default = {};
      description = ''
        Options for looking-glass.
      '';
    };

    qemu = lib.mkOption {
      type = qemuSubmodule;
      default = {};
      description = ''
        Options for qemu.
      '';
    };

    gpus = lib.mkOption {
      type = lib.types.attrsOf gpuSubmodule;
      default = {};
      description = ''
        The GPUs used for passthrough.
      '';
    };

    vms = lib.mkOption {
      type = lib.types.attrsOf vmSubmodule;
      default = {};
      description = ''
        The virtual machines.
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      boot = {
        initrd.kernelModules = ["vfio_pci"];
        kernelModules = ["vfio_pci"];
        kernelParams = [
          "${cfg.cpuType}_iommu=on"
          "iommu=pt"
          # TODO: Support binding to vfio-pci?
          #"vfio-pci.ids="
        ];
        extraModprobeConfig = ''
          options kvm-${cfg.cpuType} nested=1
          options kvm ignore_msrs=1 report_ignored_msrs=0
        '';
      };

      virtualisation.libvirtd = {
        enable = true;
        qemu.swtpm.enable = true;
        qemu.verbatimConfig = let
          allDevices =
            [
              "/dev/null"
              "/dev/full"
              "/dev/zero"
              "/dev/random"
              "/dev/urandom"
              "/dev/ptmx"
              "/dev/kvm"
              "/dev/kqemu"
              "/dev/rtc"
              "/dev/hpet"
              "/dev/sev"
            ]
            ++ cfg.qemu.devices
            ++ lib.optionals (cfg.lookingGlass.enable && cfg.lookingGlass.enableKvmfr) ["/dev/kvmfr0"];
        in ''
          user = "${cfg.qemu.user}"
          cgroup_device_acl = [
            "${lib.concatStringsSep "\", \"" allDevices}"
          ]
        '';
      };

      hardware.nvidia = lib.mkIf (lib.lists.any (gpu: gpu.driver == "nvidia") (lib.attrsets.attrValues cfg.gpus)) {
        nvidiaPersistenced = true;
        powerManagement.enable = true;
      };

      systemd.services.libvirtd = {
        path = with pkgs; [
          stdenv.shell
          util-linux
        ];
        preStart = ''
          mkdir -p /var/lib/libvirt/hooks
          ln -sf ${qemuHook} /var/lib/libvirt/hooks/qemu
        '';
      };

      environment.systemPackages = [gpuAttachAllScript gpuDetachAllScript];

      # Prevent Xorg from opening /dev/nvidia0
      services.xserver.displayManager = {
        setupCommands =
          lib.concatStringsSep "\n"
          (lib.mapAttrsToList (gpuName: gpu: (lib.getExe (gpuAttachScript gpu))) cfg.gpus);
        job.preStart =
          lib.concatStringsSep "\n"
          (lib.mapAttrsToList (gpuName: gpu: (lib.getExe (gpuDetachScript gpu))) cfg.gpus);
      };

      powerManagement.powerUpCommands =
        lib.concatStringsSep "\n"
        (lib.mapAttrsToList (gpuName: gpu: gpu.powerManagementCommands) cfg.gpus);
    }

    (lib.mkIf cfg.lookingGlass.enable {
      environment.systemPackages = [lookingGlassClient];
    })

    (lib.mkIf (cfg.lookingGlass.enable && cfg.lookingGlass.enableShm) {
      systemd.tmpfiles.rules = lib.mkIf cfg.lookingGlass.enableShm [
        "f /dev/shm/looking-glass 0660 1000 qemu-libvirtd -"
      ];
    })

    (lib.mkIf (cfg.lookingGlass.enable && cfg.lookingGlass.enableKvmfr) {
      boot = {
        kernelModules = ["kvmfr"];
        extraModulePackages = with config.boot.kernelPackages; [kvmfr];
        extraModprobeConfig = ''
          options kvmfr ${lib.optionalString (cfg.lookingGlass.kvmfrSizes != []) "static_size_mb=${lib.concatStringsSep "," (map toString cfg.lookingGlass.kvmfrSizes)}"}
        '';
      };

      services.udev.extraRules = ''
        SUBSYSTEM=="kvmfr", OWNER="${cfg.lookingGlass.kvmfrUser}", GROUP="kvm", MODE="0660"
      '';
    })

    {
      systemd.services = lib.mkMerge (lib.mapAttrsToList (vmName: vm: {
          "hibernate-vm-shutdown-${vmName}" = lib.mkIf vm.enableHibernation {
            description = "Hibernate VM ${vmName} when host shuts down";
            requires = ["virt-guest-shutdown.target"];
            after = [
              "libvirt-guests.service"
              "libvirtd.service"
              "virt-guest-shutdown.target"
            ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStop = "${lib.getExe hibernateScript} ${vmName}";
              TimeoutStopSec = "90s";
            };
            wantedBy = ["multi-user.target"];
          };

          "hibernate-vm-sleep-${vmName}" = lib.mkIf vm.enableHibernation {
            description = "Hibernate VM ${vmName} when host goes to sleep";
            before = ["sleep.target"];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${lib.getExe hibernateScript} ${vmName}";
              TimeoutStartSec = "90s";
            };
            wantedBy = ["sleep.target"];
          };
        })
        cfg.vms);
    }

    {
      environment.etc = lib.mkMerge (lib.mapAttrsToList (vmName: vm: let
          hookPath = "libvirt/hooks/qemu.d/${vmName}";
          hostCpus = lib.concatStringsSep "," vm.isolate.hostCpus;
          guestCpus = lib.concatStringsSep "," vm.isolate.guestCpus;
          allCpus = lib.concatStringsSep "," vm.isolate.allCpus;
        in {
          "${hookPath}/prepare/begin/01-detach.sh" = lib.mkIf (vm.gpu != null) {
            source = lib.getExe (gpuDetachScript cfg.gpus.${vm.gpu});
          };

          "${hookPath}/release/end/01-attach.sh" = lib.mkIf (vm.gpu != null) {
            source = lib.getExe (gpuAttachScript cfg.gpus.${vm.gpu});
          };

          "${hookPath}/prepare/begin/02-isolate.sh" = lib.mkIf vm.isolate.enable {
            source = let
              script = pkgs.writeScriptBin "isolate" ''
                #!${pkgs.stdenv.shell}
                set -e
                ${lib.optionalString vm.isolate.isolateCpus ''
                  systemctl set-property --runtime -- user.slice AllowedCPUs=${hostCpus}
                  systemctl set-property --runtime -- system.slice AllowedCPUs=${hostCpus}
                  systemctl set-property --runtime -- init.scope AllowedCPUs=${hostCpus}
                ''}

                ${lib.getExe pkgs.vfio-isolate} \
                  --undo-file /tmp/isolate-undo-${vmName} \
                  ${lib.optionalString vm.isolate.dropCaches "drop-caches"} \
                  ${lib.optionalString vm.isolate.compactMemory "compact-memory"} \
                  ${lib.optionalString vm.isolate.isolateCpus ''
                  irq-affinity mask C${guestCpus}
                ''}

                ${lib.optionalString vm.isolate.isolateCpus ''
                  taskset -pc '${hostCpus}' 2
                ''}
              '';
            in (lib.getExe script);
          };

          "${hookPath}/release/end/02-unisolate.sh" = lib.mkIf vm.isolate.enable {
            source = let
              script = pkgs.writeScriptBin "unisolate" ''
                #!${pkgs.stdenv.shell}
                set -e
                ${lib.optionalString vm.isolate.isolateCpus ''
                  systemctl set-property --runtime -- user.slice AllowedCPUs=${allCpus}
                  systemctl set-property --runtime -- system.slice AllowedCPUs=${allCpus}
                  systemctl set-property --runtime -- init.scope AllowedCPUs=${allCpus}
                ''}

                ${lib.getExe pkgs.vfio-isolate} restore /tmp/isolate-undo-${vmName}
                rm -f /tmp/isolate-undo-${vmName}

                ${lib.optionalString vm.isolate.isolateCpus ''
                  taskset -pc '${allCpus}' 2
                ''}
              '';
            in (lib.getExe script);
          };

          "${hookPath}/prepare/begin/03-start.sh" = lib.mkIf (vm.startCommands != null) {
            source = let
              script = pkgs.writeScriptBin "start" ''
                #!${pkgs.stdenv.shell}
                set -e
                ${vm.startCommands}
              '';
            in (lib.getExe script);
          };

          "${hookPath}/release/end/03-end.sh" = lib.mkIf (vm.endCommands != null) {
            source = let
              script = pkgs.writeScriptBin "end" ''
                #!${pkgs.stdenv.shell}
                set -e
                ${vm.endCommands}
              '';
            in (lib.getExe script);
          };
        })
        cfg.vms);
    }
  ]);
}
