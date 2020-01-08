{ config, pkgs, ... }:

let
  nixos-hardware = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
  };
in {
  imports = [
    "${nixos-hardware}/common/cpu/intel"
    "${nixos-hardware}/common/pc/ssd"
    ./hardware-configuration.nix
    ../../modules/common
    ../../modules/desktop
    ../../modules/mullvad-vpn
    ../../modules/syncthing
    ../../home
    ./telegraf.nix
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = [ "zfs" ];
    zfs.extraPools = [ "tank" ];
    blacklistedKernelModules = [ "nouveau" ];
    kernelModules = [
      "i2c-dev" # for ddcutil
      "vfio_pci"
    ];
    kernelParams = [
      "intel_iommu=on"
      "iommu=pt"
      "default_hugepagesz=1G" "hugepagesz=1G" "hugepages=16"
      "pcie_acs_override=downstream"
    ];
    kernelPatches = [ {
      name = "acs";
      patch = pkgs.fetchurl {
        url = "https://aur.archlinux.org/cgit/aur.git/plain/add-acs-overrides.patch?h=linux-vfio";
        sha256 = "1qd68s9r0ppynksbffqn2qbp1whqpbfp93dpccp9griwhx5srx6v";
      };
    } ];
    extraModprobeConfig = ''
      options kvm ignore_msrs=1
    '';
  };

  networking = {
    hostName = "valmar";
    hostId = "203d588e";
    bridges.br0.interfaces = [ "enp0s31f6" ];
    interfaces.enp2s0f0 = {
      ipv4.addresses = [ {
        address = "192.168.10.2";
        prefixLength = 24;
      } ];
      mtu = 9000;
    };
    hosts = {
      "192.168.10.1" = [ "elena-10g" ];
    };
  };

  services = {
    xserver = {
      xkbOptions = "ctrl:nocaps, shift:both_capslock";
      videoDrivers = [ "intel" /*"nvidia"*/ ]; # TODO: enabling nvidia disables glx
    };

    zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };

    znapzend = {
      enable = true;
      pure = true;
      autoCreation = true;
      zetup = {
        "rpool/home" = {
          plan = "1day=>1hour,1week=>1day,1month=>1week";
          destinations.remote = {
            host = "elena";
            dataset = "tank/backup/hosts/${config.networking.hostName}/home";
            plan = "1week=>1day,1month=>1week,3month=>1month";
          };
        };
        "rpool/root/nixos" = {
          recursive = true;
          plan = "1day=>1hour,1week=>1day,1month=>1week";
          destinations.remote = {
            host = "elena";
            dataset = "tank/backup/hosts/${config.networking.hostName}/root/nixos";
            plan = "1week=>1day,1month=>1week,3month=>1month";
          };
        };
      };
    };
  };

  fileSystems."/var/lib/libvirt/images" = {
    device = "elena-10g:/images";
    fsType = "nfs";
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      qemuVerbatimConfig = ''
        user = "aostanin"
        cgroup_device_acl = [
          "/dev/null", "/dev/full", "/dev/zero",
          "/dev/random", "/dev/urandom",
          "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
          "/dev/rtc","/dev/hpet", "/dev/sev",
          "/dev/input/by-id/usb-04d9_USB_Keyboard-event-kbd",
          "/dev/input/by-id/usb-Logitech_G500s_Laser_Gaming_Mouse_2881723C750008-event-mouse"
        ]
      '';
    };

    docker = {
      enable = true;
      storageDriver = "zfs";
    };
  };
}
