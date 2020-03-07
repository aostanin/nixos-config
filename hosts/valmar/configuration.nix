{ config, pkgs, ... }:

let
  nvidia_x11 = config.boot.kernelPackages.nvidia_x11;
in {
  imports = [
    <nixos-hardware/common/cpu/intel>
    <nixos-hardware/common/pc/ssd>
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
    extraModulePackages = [ nvidia_x11.bin ];
    blacklistedKernelModules = [ "nouveau" ];
    kernelModules = [
      "nvidia-uvm"
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
      options bonding max_bonds=0
      options kvm ignore_msrs=1
      options kvm-intel nested=1
    '';
  };

  hardware.opengl = {
    extraPackages = [ nvidia_x11.out ];
    extraPackages32 = [ nvidia_x11.lib32 ];
  };

  environment.systemPackages = [
    nvidia_x11.bin
    nvidia_x11.settings
    nvidia_x11.persistenced
  ];

  networking = {
    hostName = "valmar";
    hostId = "203d588e";

    bonds.bond0 = {
      interfaces = [
        "enp0s31f6" # 1G
        "enp2s0f0"  # 10G
      ];
      driverOptions = {
        mode = "active-backup";
        miimon = "100";
        primary = "enp2s0f0";
      };
    };
    bridges.br0 = {
      interfaces = [ "bond0" ];
      rstp = true;
    };
    interfaces.br0 = {
      useDHCP = true;
      macAddress = "6a:c7:9c:df:fc:96";
    };
  };

  services = {
    xserver = {
      xkbOptions = "ctrl:nocaps, shift:both_capslock";
      videoDrivers = [ "intel" ];
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

  fileSystems."/var/lib/libvirt/images/remote" = {
    device = "elena.lan:/images";
    fsType = "nfs";
  };

  fileSystems."/mnt/media" = {
    device = "elena.lan:/media";
    fsType = "nfs";
  };

  programs.adb.enable = true;

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
          "/dev/input/by-id/usb-Logitech_G500s_Laser_Gaming_Mouse_2881723C750008-event-mouse",
          "/dev/input/by-id/usb-SINOWEALTH_Wired_Gaming_Mouse-event-mouse"
        ]
      '';
    };

    docker = {
      enable = true;
      enableNvidia = true;
      storageDriver = "zfs";
    };
  };
}
