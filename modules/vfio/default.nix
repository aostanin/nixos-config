{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.services.vfio;

  libvirt = config.virtualisation.libvirtd.package;
  nvidiaBin = pkgs.linuxPackages.nvidia_x11.bin;

  qemuSubmodule = types.submodule {
    options = {
      user = mkOption {
        type = types.str;
        default = "root";
        example = "bob";
        description = ''
          The user to run qemu as.
        '';
      };

      devices = mkOption {
        type = types.listOf types.str;
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

  gpuSubmodule = types.submodule {
    options = {
      driver = mkOption {
        type = types.str;
        example = "nvidia";
        description = ''
          Currently only "nvidia" is supported.
        '';
      };

      pciIds = mkOption {
        type = types.listOf types.str;
        example = ["1458:22f7" "1458:aaf0"];
        description = ''
          The PCI ids of the GPU devices.
        '';
      };

      busId = mkOption {
        type = types.str;
        example = "0a:00.0";
        description = ''
          The bus id in the same format as lspci.
        '';
      };

      powerManagementCommands = mkOption {
        type = types.str;
        description = ''
          Commands to run when the card is detached to put it in a low power state.
        '';
      };
    };
  };

  isolateSubmodule = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          Run vfio-isolate before starting the VM.
        '';
      };

      dropCaches = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          Drop caches before starting the VM.
        '';
      };

      compactMemory = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          Compact memory before starting the VM.
        '';
      };

      isolateCpus = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          Isolate CPUs before starting the VM.
        '';
      };

      allCpus = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["0-23"];
        description = ''
          List of ranges for all host CPUs.
        '';
      };

      hostCpus = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["0-5" "12-17"];
        description = ''
          List of ranges for the remaining host CPUs.
        '';
      };

      guestCpus = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["0-1" "12-13" "6-11" "18-23"];
        description = ''
          List of ranges for the guest CPUs.
        '';
      };
    };
  };

  vmSubmodule = types.submodule {
    options = {
      gpu = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "amdRX570";
        description = ''
          Which GPU to use for this VM.
        '';
      };

      enableHibernation = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          Hibernate the VM when the host shuts down or goes to sleep.
        '';
      };

      isolate = mkOption {
        type = isolateSubmodule;
        default = {};
        description = ''
          Settings for vfio-isolate.
        '';
      };
    };
  };

  # https://github.com/PassthroughPOST/VFIO-Tools/blob/master/libvirt_hooks/qemu
  qemuHook = pkgs.writeShellScript "qemu" ''
    #!${pkgs.stdenv.shell}
    #
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

  lookingGlassClient = pkgs.looking-glass-client.overrideAttrs (old: rec {
    version = "B6";
    src = pkgs.fetchFromGitHub {
      owner = "gnif";
      repo = "LookingGlass";
      rev = version;
      sha256 = "sha256-6vYbNmNJBCoU23nVculac24tHqH7F4AZVftIjL93WJU=";
      fetchSubmodules = true;
    };
    buildInputs =
      old.buildInputs
      ++ (with pkgs; [
        pipewire
        libpulseaudio
        libsamplerate
      ]);
  });

  # https://gist.github.com/Roliga/928cd44440f4df74e796e4e1315034bf
  hibernateScript = pkgs.writeScriptBin "hibernate-vm" ''
    #!${pkgs.stdenv.shell}

    #
    # Usage: hibernate-vm NAME
    #
    # Hibernates the VM specified in NAME and waits for it to finish shutting down
    #

    if ${pkgs.libvirt}/bin/virsh dompmsuspend "$1" disk; then
      echo "Waiting for domain to finish shutting down.." >&2
      while ! [ "$(${pkgs.libvirt}/bin/virsh domstate "$1")" == 'shut off' ]; do
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

        if [ -d /sys/bus/pci/drivers/amdgpu/0000:${gpu.busId} ]; then
          echo 0000:${gpu.busId} > /sys/bus/pci/drivers/amdgpu/unbind
        fi

        # Binding to amdgpu resizes the BAR from 256MB to 4GB (on RX 570). This causes Windows
        # guests to fail initializing DirectX and macOS guests to hang during boot.
        # Setting the BAR size back to 256MB before starting the VM fixes these issues.
        echo 8 > /sys/bus/pci/devices/0000:${gpu.busId}/resource0_resize

        if [ $(basename $(readlink /sys/bus/pci/devices/0000:${gpu.busId}/driver)) != "vfio-pci" ]; then
          ${libvirt}/bin/virsh nodedev-detach pci_0000_${(replaceStrings [":" "."] ["_" "_"] gpu.busId)}
        fi
      ''
      else if (gpu.driver == "nvidia")
      then ''
        #!${pkgs.stdenv.shell}
        set -e

        systemctl stop nvidia-persistenced.service

        # Avoid detaching the GPU if it's in use
        fuser /dev/nvidia0 && exit 1

        if [ $(basename $(readlink /sys/bus/pci/devices/0000:${gpu.busId}/driver)) != "vfio-pci" ]; then
          ${libvirt}/bin/virsh nodedev-detach pci_0000_${(replaceStrings [":" "."] ["_" "_"] gpu.busId)}
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
          ${libvirt}/bin/virsh nodedev-reattach pci_0000_${(replaceStrings [":" "."] ["_" "_"] gpu.busId)}
        fi

        ${gpu.powerManagementCommands}
      ''
      else if (gpu.driver == "nvidia")
      then ''
        #!${pkgs.stdenv.shell}
        set -e

        if [ $(basename $(readlink /sys/bus/pci/devices/0000:${gpu.busId}/driver)) == "vfio-pci" ]; then
          ${libvirt}/bin/virsh nodedev-reattach pci_0000_${(replaceStrings [":" "."] ["_" "_"] gpu.busId)}
        fi

        systemctl start nvidia-persistenced.service

        ${gpu.powerManagementCommands}
      ''
      else throw "Unsupported gpu driver ${gpu.driver}"
    );
in {
  options.services.vfio = {
    enable = mkEnableOption "vfio";

    cpuType = mkOption {
      type = types.str;
      example = "amd";
      description = ''
        The host CPU type, either "intel" or "amd".
      '';
    };

    enableLookingGlass = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Enable support for looking-glass-client.
      '';
    };

    qemu = mkOption {
      type = qemuSubmodule;
      default = {};
      description = ''
        Options for qemu.
      '';
    };

    gpus = mkOption {
      type = types.attrsOf gpuSubmodule;
      description = ''
        The GPUs used for passthrough.
      '';
    };

    vms = mkOption {
      type = types.attrsOf vmSubmodule;
      default = {};
      description = ''
        The virtual machines.
      '';
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
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
            ++ cfg.qemu.devices;
        in ''
          user = "${cfg.qemu.user}"
          cgroup_device_acl = [
            "${concatStringsSep "\", \"" allDevices}"
          ]
        '';
      };

      hardware.nvidia.nvidiaPersistenced = true;

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

      # Prevent Xorg from opening /dev/nvidia0
      services.xserver.displayManager = {
        setupCommands =
          concatStringsSep "\n"
          (mapAttrsToList (gpuName: gpu: "${gpuAttachScript gpu}/bin/vfio-gpu-attach") cfg.gpus);
        job.preStart =
          concatStringsSep "\n"
          (mapAttrsToList (gpuName: gpu: "${gpuDetachScript gpu}/bin/vfio-gpu-detach") cfg.gpus);
      };

      powerManagement.powerUpCommands =
        concatStringsSep "\n"
        (mapAttrsToList (gpuName: gpu: gpu.powerManagementCommands) cfg.gpus);
    })

    (mkIf (cfg.enable && cfg.enableLookingGlass) {
      environment.systemPackages = [lookingGlassClient];

      systemd.tmpfiles.rules = [
        "f /dev/shm/looking-glass 0660 1000 qemu-libvirtd -"
      ];
    })

    {
      systemd.services = mkMerge (mapAttrsToList (vmName: vm: {
          "hibernate-vm-shutdown-${vmName}" = mkIf vm.enableHibernation {
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
              ExecStop = "${hibernateScript}/bin/hibernate-vm ${vmName}";
            };
            wantedBy = ["multi-user.target"];
          };

          "hibernate-vm-sleep-${vmName}" = mkIf vm.enableHibernation {
            description = "Hibernate VM ${vmName} when host goes to sleep";
            before = ["sleep.target"];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${hibernateScript}/bin/hibernate-vm ${vmName}";
            };
            wantedBy = ["sleep.target"];
          };
        })
        cfg.vms);
    }

    {
      environment.etc = mkMerge (mapAttrsToList (vmName: vm: let
          hookPath = "libvirt/hooks/qemu.d/${vmName}";
        in {
          "${hookPath}/prepare/begin/01-detach.sh" = mkIf (vm.gpu != null) {
            source = "${gpuDetachScript cfg.gpus.${vm.gpu}}/bin/vfio-gpu-detach";
          };

          "${hookPath}/release/end/01-attach.sh" = mkIf (vm.gpu != null) {
            source = "${gpuAttachScript cfg.gpus.${vm.gpu}}/bin/vfio-gpu-attach";
          };

          "${hookPath}/prepare/begin/02-isolate.sh" = mkIf vm.isolate.enable {
            source = let
              script = pkgs.writeScriptBin "isolate" ''
                #!${pkgs.stdenv.shell}
                set -e
                HCPUS='${concatStringsSep "," vm.isolate.hostCpus}'
                MCPUS='${concatStringsSep "," vm.isolate.guestCpus}'

                ${pkgs.vfio-isolate}/bin/vfio-isolate \
                  --undo-file /tmp/isolate-undo-${vmName} \
                  ${optionalString vm.isolate.dropCaches "drop-caches"} \
                  ${optionalString vm.isolate.isolateCpus "cpuset-modify --cpus C$HCPUS /system.slice"} \
                  ${optionalString vm.isolate.isolateCpus "cpuset-modify --cpus C$HCPUS /user.slice"} \
                  ${optionalString vm.isolate.compactMemory "compact-memory"} \
                  ${optionalString vm.isolate.isolateCpus ''
                  irq-affinity mask C$MCPUS \
                  cpu-governor performance C$MCPUS
                ''}

                ${optionalString vm.isolate.isolateCpus ''
                  taskset -pc $HCPUS 2
                ''}
              '';
            in "${script}/bin/isolate";
          };

          "${hookPath}/release/end/02-unisolate.sh" = mkIf vm.isolate.enable {
            source = let
              script = pkgs.writeScriptBin "unisolate" ''
                #!${pkgs.stdenv.shell}
                set -e
                ${pkgs.vfio-isolate}/bin/vfio-isolate restore /tmp/isolate-undo-${vmName}
                rm -f /tmp/isolate-undo-${vmName}

                ${optionalString vm.isolate.isolateCpus ''
                  taskset -pc '${concatStringsSep "," vm.isolate.allCpus}' 2
                ''}
              '';
            in "${script}/bin/unisolate";
          };
        })
        cfg.vms);
    }
  ];
}
