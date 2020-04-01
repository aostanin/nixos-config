{ config, pkgs, ... }:

let
  screamReceivers = (pkgs.scream-receivers.override { pulseSupport = true; });
  gameScript = pkgs.writeScriptBin "game" ''
    #!${pkgs.stdenv.shell}

    virsh start win10-play
    ${pkgs.looking-glass-client}/bin/looking-glass-client -s &
    ${screamReceivers}/bin/scream-pulse &

    wait -n
    pkill -P $$
  '';
in {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest; # Avoid kernel panic for IOMMU
    kernelModules = [
      "vfio_pci"
    ];
    kernelParams = [
      "amd_iommu=on" "iommu=pt"
      "default_hugepagesz=1G" "hugepagesz=1G" "hugepages=32"
      #"vfio-pci.ids=10de:1b81,10de:10f0" # GTX 1070
      "vfio-pci.ids=10de:1e84,10de:10f8,10de:1ad8,10de:1ad9" # GTX 2070 Super
    ];
    extraModprobeConfig = ''
      options kvm-amd nested=1
    '';
  };

  environment.systemPackages = with pkgs; [
    gameScript
    looking-glass-client
    screamReceivers
    virtmanager
  ];

  systemd.tmpfiles.rules = [
    "f /dev/shm/looking-glass 0660 aostanin qemu-libvirtd -"
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemuVerbatimConfig = ''
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
