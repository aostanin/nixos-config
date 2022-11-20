{
  config,
  pkgs,
  ...
}: let
  # gpuPciIds = "1458:22f7,1458:aaf0"; # RX 570
  gpuPciIds = "10de:1e84,10de:10f8,10de:1ad8,10de:1ad9"; # RTX 2070 Super
  usbPciIds = "1b73:1100";
  gpuBusId = "pci_0000_0b_00_0";
  vmName = "win10-play";
  lookingGlassClient = pkgs.looking-glass-client.overrideAttrs (old: rec {
    # TODO: Remove once merged https://github.com/NixOS/nixpkgs/pull/192430
    version = "B6-rc1";
    src = pkgs.fetchFromGitHub {
      owner = "gnif";
      repo = "LookingGlass";
      rev = version;
      sha256 = "sha256-FZjwLY2XtPGhwc/GyAAH2jvFOp61lSqXqXjz0UBr7uw=";
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
  vfio-isolate = pkgs.python3Packages.callPackage ../../packages/vfio-isolate {};
  gameScript = pkgs.writeScriptBin "game" ''
    #!${pkgs.stdenv.shell}

    virsh start ${vmName}
    ${lookingGlassClient}/bin/looking-glass-client
  '';
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

    BASEDIR="$(dirname $0)"

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
in {
  boot = {
    initrd.kernelModules = [
      "vfio_pci"
    ];
    kernelModules = [
      "vfio_pci"
    ];
    kernelParams = [
      "amd_iommu=on"
      "iommu=pt"
      #"vfio-pci.ids=${gpuPciIds},${usbPciIds}"
      #"vfio-pci.ids=${usbPciIds}"
    ];
    extraModprobeConfig = ''
      options kvm-amd nested=1
    '';
  };

  # Prevent Xorg from opening /dev/nvidia0 by binding to vfio_pci
  services.xserver.displayManager = {
    setupCommands = "${pkgs.libvirt}/bin/virsh nodedev-reattach ${gpuBusId}";
    job.preStart = "${pkgs.libvirt}/bin/virsh nodedev-detach ${gpuBusId}";
  };

  environment.systemPackages = with pkgs; [
    gameScript
    lookingGlassClient
    vfio-isolate
    virtmanager
  ];

  systemd = {
    services.libvirtd = {
      path = with pkgs; [
        stdenv.shell
        util-linux
        vfio-isolate
      ];
      preStart = ''
        mkdir -p /var/lib/libvirt/hooks/qemu.d
        ln -sf ${qemuHook} /var/lib/libvirt/hooks/qemu
      '';
    };

    tmpfiles.rules = [
      "f /dev/shm/looking-glass 0660 aostanin qemu-libvirtd -"
    ];

    services."hibernate-vm-shutdown-${vmName}" = {
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
    services."hibernate-vm-sleep-${vmName}" = {
      description = "Hibernate VM ${vmName} when host goes to sleep";
      before = ["sleep.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${hibernateScript}/bin/hibernate-vm ${vmName}";
      };
      wantedBy = ["sleep.target"];
    };
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu.verbatimConfig = ''
      user = "aostanin"
      cgroup_device_acl = [
        "/dev/null", "/dev/full", "/dev/zero",
        "/dev/random", "/dev/urandom",
        "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
        "/dev/rtc","/dev/hpet", "/dev/sev",
        "/dev/input/by-id/usb-04d9_USB_Keyboard-event-kbd",
        "/dev/input/by-id/usb-Logitech_G500s_Laser_Gaming_Mouse_2881723C750008-event-mouse",
        "/dev/input/by-id/usb-SINOWEALTH_Wired_Gaming_Mouse-event-mouse"
      ]
    '';
  };
}
