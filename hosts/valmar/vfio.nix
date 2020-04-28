{ config, pkgs, ... }:
let
  unstable = import <unstable> { };
  gameScript = pkgs.writeScriptBin "game" ''
    #!${pkgs.stdenv.shell}

    virsh start win10-play
    ${pkgs.looking-glass-client}/bin/looking-glass-client -s &
    ${pkgs.scream-receivers}/bin/scream-pulse &

    wait -n
    pkill -P $$
  '';
in
{
  boot = {
    kernelModules = [
      "vfio_pci"
    ];
    kernelParams = [
      "amd_iommu=on"
      "iommu=pt"
      "default_hugepagesz=1G"
      "hugepagesz=1G"
      "hugepages=32"
      #"vfio-pci.ids=10de:1b81,10de:10f0" # GTX 1070
      "vfio-pci.ids=10de:1e84,10de:10f8,10de:1ad8,10de:1ad9" # RTX 2070 Super
    ];
    kernelPatches = [
      {
        # https://www.reddit.com/r/VFIO/comments/eba5mh/workaround_patch_for_passing_through_usb_and/
        name = "pcie_no_flr";
        patch = pkgs.fetchurl {
          url = "https://gist.githubusercontent.com/JKJameson/b24c972dbbb80bb330a0a1c4e8349cd3/raw/4bc4f788deeb45570023541650822503e6778d48/pcie_no_flr.patch";
          sha256 = "09wjj6qlha5c0zya3n4zbsli88siv9y04vsv5lqnbr8hnrs9z0hr";
        };
      }
    ];
    extraModprobeConfig = ''
      options kvm-amd nested=1
    '';
  };

  environment.systemPackages = with pkgs; [
    gameScript
    looking-glass-client
    scream-receivers
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
