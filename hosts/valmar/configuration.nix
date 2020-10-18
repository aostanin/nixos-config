{ config, pkgs, ... }:
let
  secrets = import ../../secrets;
in
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
      #systemd-boot.enable = true; # TODO: Switch back to systemd-boot when ipxe can be added
      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
        copyKernels = true; # Workaround ZFS issue https://nixos.wiki/wiki/NixOS_on_ZFS#Known_issues
        extraEntries = ''
          menuentry "iPXE - Windows 10 Play" {
            chainloader @bootRoot@/ipxe-win10-play.efi
          }
        '';
        extraFiles."ipxe-win10-play.efi" = let ipxe = pkgs.ipxe.override {
          embedScript = pkgs.writeText "win10-play.ipxe" ''
            #!ipxe
            ifopen net0
            set net0/ip ${secrets.network.home.hosts.valmar.address}
            set net0/netmask 255.255.255.0

            set iscsi-target-host ${secrets.network.home.hosts.elena.address}
            set iscsi-target-iqn iqn.2003-01.org.linux-iscsi.elena.x8664
            set initiator-iqn iqn.1991-05.com.microsoft:desktop-ju4818u

            set net0/gateway 0.0.0.0
            set keep-san 1

            sanboot iscsi:''${iscsi-target-host}:::0:''${iscsi-target-iqn}:sn.076cc16bd2ea
          '';
        }; in "${ipxe}/ipxe.efi";
      };
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = [ "zfs" ];
    kernelModules = [
      "i2c-dev" # for ddcutil
      "it87"
    ];
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
      macAddress = secrets.network.home.hosts.valmar.macAddress;
      ipv4.addresses = [{
        address = secrets.network.home.hosts.valmar.address;
        prefixLength = 24;
      }];
    };

    defaultGateway = secrets.network.home.defaultGateway;
    nameservers = [ secrets.network.home.nameserverPihole ];
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
    device = "${secrets.network.home.hosts.elena.address}:/images";
    fsType = "nfs";
  };

  fileSystems."/mnt/media" = {
    device = "${secrets.network.home.hosts.elena.address}:/media";
    fsType = "nfs";
  };

  fileSystems."/mnt/personal" = {
    device = "${secrets.network.home.hosts.elena.address}:/personal";
    fsType = "nfs";
  };

  programs.adb.enable = true;

  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
    storageDriver = "zfs";
  };
}
