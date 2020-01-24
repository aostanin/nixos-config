{ config, pkgs, ... }:

{
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
      options bonding max_bonds=0
      options kvm ignore_msrs=1
      options kvm-intel nested=1
    '';
  };

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

  # TODO: This doesn't work for some reason
  # systemd.network = {
  #   enable = true;

  #   netdevs = {
  #     bond0 = {
  #       netdevConfig = {
  #         Name = "bond0";
  #         Kind = "bond";
  #       };
  #       bondConfig = {
  #         Mode = "active-backup";
  #         MIIMonitorSec = "100ms";
  #       };
  #     };
  #     br0 = {
  #       netdevConfig = {
  #         Name = "br0";
  #         Kind = "bridge";
  #         MACAddress = "6a:c7:9c:df:fc:96";
  #       };
  #       extraConfig = ''
  #         [Bridge]
  #         VLANFiltering=yes
  #         STP=yes
  #       '';
  #     };
  #   };

  #   networks = {
  #     enp0s31f6 = {
  #       matchConfig = { Name = "enp0s31f6"; };
  #       networkConfig = {
  #         Bond = "bond0";
  #       };
  #     };
  #     enp2s0f0 = {
  #       matchConfig = { Name = "enp2s0f0"; };
  #       networkConfig = {
  #         Bond = "bond0";
  #         PrimarySlave = "yes";
  #       };
  #     };
  #     bond0 = {
  #       matchConfig = { Name = "bond0"; };
  #       networkConfig = {
  #         Bridge = "br0";
  #       };
  #     };
  #     br0 = {
  #       matchConfig = { Name = "br0"; };
  #       networkConfig = {
  #         DHCP = "yes";
  #       };
  #     };
  #   };
  # };

  services = {
    xserver = {
      xkbOptions = "ctrl:nocaps, shift:both_capslock";
      videoDrivers = [ "intel" "nvidia" ];
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
