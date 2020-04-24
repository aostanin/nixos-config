{ config, pkgs, ... }:

{
  imports = [
    <nixos-hardware/common/cpu/amd>
    <nixos-hardware/common/pc/ssd>
    ./hardware-configuration.nix
    ../../modules/variables
    ../../modules/common
    ../../modules/desktop
    ../../modules/syncthing
    ../../modules/zerotier
    ../../home
    ./telegraf.nix
    ./vfio.nix
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = [ "zfs" ];
    zfs.extraPools = [ "tank" ];
    kernelModules = [
      "i2c-dev" # for ddcutil
      "it87"
    ];
    extraModprobeConfig = ''
      options bonding max_bonds=0
    '';
  };

  networking = {
    hostName = "valmar";
    hostId = "203d588e";

    bonds.bond0 = {
      interfaces = [
        "enp6s0" # 1G
        "enp4s0f0" # 10G
      ];
      driverOptions = {
        mode = "active-backup";
        miimon = "100";
        primary = "enp4s0f0";
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
    wakeonlan.interfaces = [
      {
        interface = "enp6s0";
        method = "magicpacket";
      }
    ];

    xserver = {
      videoDrivers = [ "nvidia" ];
      xkbOptions = "ctrl:nocaps, shift:both_capslock";
      screenSection = ''
        # Fix for screen tearing: https://wiki.archlinux.org/index.php/NVIDIA/Troubleshooting#Avoid_screen_tearing
        Option "metamodes" "DPY-0: nvidia-auto-select +440+0 {ForceFullCompositionPipeline=On}, DPY-1: nvidia-auto-select +0+1440 {ForceFullCompositionPipeline=On}"
      '';
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
        "rpool/virtualization/libvirt" = {
          recursive = true;
          plan = "1day=>1hour,1week=>1day,1month=>1week";
          destinations.remote = {
            host = "elena";
            dataset = "tank/backup/hosts/${config.networking.hostName}/virtualization/libvirt";
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

  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
    storageDriver = "zfs";
  };
}
