{ config, pkgs, ... }:
let
  lookingGlassClient = pkgs.looking-glass-client;
  vfio-isolate = pkgs.python3Packages.callPackage ../../packages/vfio-isolate { };
  gameScript = pkgs.writeScriptBin "game" ''
    #!${pkgs.stdenv.shell}

    virsh start win10-play
    ${lookingGlassClient}/bin/looking-glass-client
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
in
{
  boot = {
    initrd.kernelModules = [
      "vfio_pci"
    ];
    kernelModules = [
      "vfio_pci"
    ];
    kernelParams =
      let
        # gpuPciIds = "1458:22f7,1458:aaf0"; # RX 570
        gpuPciIds = "10de:1e84,10de:10f8,10de:1ad8,10de:1ad9"; # RTX 2070 Super
        usbPciIds = "1b73:1100";
      in
      [
        "amd_iommu=on"
        "iommu=pt"
        "vfio-pci.ids=${gpuPciIds},${usbPciIds}"
      ];
    extraModprobeConfig = ''
      options kvm-amd nested=1
    '';
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
