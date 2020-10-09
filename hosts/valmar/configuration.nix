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
    kernelModules = [
      "i2c-dev" # for ddcutil
      "it87"
    ];
    extraModprobeConfig = ''
      options bonding max_bonds=0
    '';
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  networking = {
    hostName = "valmar";
    hostId = "203d588e";

    bridges.br0 = {
      interfaces = [ "enp4s0f0" ];
      rstp = true;
    };
    interfaces.br0 = {
      macAddress = "6a:c7:9c:df:fc:96";
      ipv4.addresses = [{
        address = "10.0.0.12";
        prefixLength = 24;
      }];
    };

    defaultGateway = "10.0.0.1";
    nameservers = [ "10.0.0.10" ];
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
    device = "10.0.0.10:/images";
    fsType = "nfs";
  };

  fileSystems."/mnt/media" = {
    device = "10.0.0.10:/media";
    fsType = "nfs";
  };

  fileSystems."/mnt/personal" = {
    device = "10.0.0.10:/personal";
    fsType = "nfs";
  };

  programs.adb.enable = true;

  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
    storageDriver = "zfs";
  };
}
