{ config, pkgs, hardwareModulesPath, ... }:
let
  secrets = import ../../secrets;
in
{
  imports = [
    "${hardwareModulesPath}/common/cpu/amd"
    "${hardwareModulesPath}/common/pc/ssd"
    ./hardware-configuration.nix
    ../../modules/variables
    ../../modules/common
    ../../modules/desktop
    ../../modules/scrutiny
    ../../modules/ssmtp
    ../../modules/zerotier
    ./ipxe.nix
    ./telegraf.nix
    ./vfio.nix
    ./tdarr.nix
  ];

  boot = {
    loader = {
      systemd-boot.enable = true; # TODO: Switch back to systemd-boot when ipxe can be added
      grub = {
        #enable = true; # TODO: Disabled due to bug https://github.com/NixOS/nixpkgs/issues/127925
        efiSupport = true;
        device = "nodev";
        copyKernels = true; # Workaround ZFS issue https://nixos.wiki/wiki/NixOS_on_ZFS#Known_issues
      };
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = [ "zfs" ];
    extraModulePackages = with config.boot.kernelPackages; [
      zenpower
    ];
    kernelModules = [
      "amdgpu"
      "it87"
    ];
    blacklistedKernelModules = [
      "k10temp" # Use zenpower
      "nouveau"
    ];
    binfmt.emulatedSystems = [ "aarch64-linux" ];
    zfs.extraPools = [ "tank" ];
  };

  hardware.opengl.extraPackages = with pkgs; [
    amdvlk
    rocm-opencl-icd
  ];

  networking = {
    hostName = "valmar";
    hostId = "203d588e";

    bridges.br0.interfaces = [ "enp4s0f0" ];
    interfaces = {
      br0 = {
        macAddress = secrets.network.home.hosts.valmar.macAddress;
        ipv4.addresses = [{
          address = secrets.network.home.hosts.valmar.address;
          prefixLength = 24;
        }];
      };

      enp4s0f1 = {
        mtu = 9000;
        ipv4.addresses = [{
          address = secrets.network.storage.hosts.valmar.address;
          prefixLength = 24;
        }];
      };

      enp5s0 = {
        wakeOnLan.enable = true;
      };
    };

    defaultGateway = secrets.network.home.defaultGateway;
    nameservers = [ secrets.network.home.nameserverPihole ];
  };

  services = {
    udev = {
      extraRules = ''
        # Disable Bluetooth dongle passed to Windows VM
        SUBSYSTEM=="usb", ATTRS{idVendor}=="0a12", ATTRS{idProduct}=="0001", ATTRS{busnum}=="1", ATTR{authorized}="0"

        # TODO: Temporary workaround for MTU not being set
        ACTION=="add", SUBSYSTEM=="net", KERNELS=="0000:04:00.1", ATTR{mtu}="9000"
      '';
      packages = [
        pkgs.stlink
      ];
    };

    xserver = {
      videoDrivers = [ "amdgpu" ];
      deviceSection = ''
        Option "TearFree" "true"
      '';
      xkbOptions = "ctrl:nocaps, shift:both_capslock";
      xrandrHeads = [
        {
          output = "HDMI-A-0";
          primary = true;
          monitorConfig = ''
            Option "Position" "0 1440"
          '';
        }
        {
          output = "DVI-D-0";
          monitorConfig = ''
            Option "Position" "440 0"
          '';
        }
      ];
    };

    zfs = {
      autoScrub = {
        enable = true;
        interval = "monthly";
      };
      autoSnapshot = {
        enable = true;
        monthly = 0;
      };
      trim.enable = true;
      zed = {
        enableMail = true;
        settings = {
          ZED_EMAIL_ADDR = secrets.user.emailAddress;
          ZED_NOTIFY_VERBOSE = true;
        };
      };
    };

    znapzend = {
      enable = true;
      pure = true;
      autoCreation = true;
      features = {
        compressed = true;
        recvu = true;
        zfsGetType = true;
      };
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

  fileSystems = let nfsFilesystem = path: {
    device = "${secrets.network.storage.hosts.elena.address}:${path}";
    fsType = "nfs";
  }; in
    {
      "/var/lib/libvirt/images/remote" = nfsFilesystem "/images";
      "/mnt/media" = nfsFilesystem "/media";
      "/mnt/personal" = nfsFilesystem "/personal";
      "/mnt/appdata" = nfsFilesystem "/appdata";
    };

  programs.adb.enable = true;

  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
    storageDriver = "zfs";
    autoPrune = {
      enable = true;
      flags = [
        "--all"
        "--filter \"until=168h\""
      ];
    };
  };
}
