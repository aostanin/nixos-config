{ config, pkgs, ... }:

{
  imports = [
    <nixos-hardware/common/cpu/amd>
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
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [
      "i2c-dev" # for ddcutil
      "vfio_pci"
    ];
    kernelParams = [
      "amd_iommu=on" "iommu=pt"                              # IOMMU
      "default_hugepagesz=1G" "hugepagesz=1G" "hugepages=32" # Huge pages
      "vfio-pci.ids=10de:1b81"
      # "vfio-pci.ids=10de:1b81,10de:10f0"
      #"video=vesafb:off,efifb:off"                           # Disable framebuffer
      #"pcie_aspm=off"
      #"pcie_acs_override=downstream"
    ];
    #kernelPatches = [ {
      #name = "acs";
      #patch = pkgs.fetchurl {
        #name = "add-acs-overrides.patch";
        #url = "https://aur.archlinux.org/cgit/aur.git/plain/add-acs-overrides.patch?h=linux-vfio&id=84d928649b39b791a894aac9a29547182b7c2a52";
        #sha256 = "1qd68s9r0ppynksbffqn2qbp1whqpbfp93dpccp9griwhx5srx6v";
      #};
    #} ];
    extraModprobeConfig = ''
      options bonding max_bonds=0
      options kvm-amd nested=1
      options snd-hda-intel enable_msi=1 # Fix audio in VFIO
    '';
  };

  hardware = {
    #pulseaudio.extraConfig = ''
      #set-default-sink alsa_output.pci-0000_00_1f.3.hdmi-stereo-extra1
      #set-card-profile alsa_card.pci-0000_00_1f.3 output:hdmi-stereo-extra1
    #'';
  };

  networking = {
    hostName = "valmar";
    hostId = "203d588e";

    bonds.bond0 = {
      interfaces = [
        "enp5s0"   # 1G
        "enp10s0f0" # 10G
      ];
      driverOptions = {
        mode = "active-backup";
        miimon = "100";
        primary = "enp10s0f0";
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
      #videoDrivers = [ "nvidia" ];
      xkbOptions = "ctrl:nocaps, shift:both_capslock";
      #xrandrHeads = [
        #{
          #output = "HDMI2";
          #primary = true;
          #monitorConfig = ''
            #Option "Position" "0 1440"
            #Option "PreferredMode" "3440x1440"
          #'';
        #}
        #{
          #output = "DP1";
          #monitorConfig = ''
            #Option "Position" "440 0"
            #Option "PreferredMode" "2560x1440"
          #'';
        #}
      #];
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
