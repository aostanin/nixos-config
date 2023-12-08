{
  config,
  pkgs,
  lib,
  hardwareModulesPath,
  secrets,
  ...
}: let
  iface = "enx${lib.replaceStrings [":"] [""] secrets.network.nics.elena.expansion10GbE0}";
  ifaceStorage = "enx${lib.replaceStrings [":"] [""] secrets.network.nics.elena.expansion10GbE1}";
in {
  imports = [
    "${hardwareModulesPath}/common/cpu/intel"
    "${hardwareModulesPath}/common/pc/ssd"
    ./hardware-configuration.nix
    ../../modules
    ../../modules/common
    ../../modules/msmtp
    ../../modules/zerotier
    ./backup.nix
    ./backup-external.nix
    #./i915-sriov.nix
    ./nfs.nix
    ./power-management.nix
  ];

  boot = {
    loader = {
      grub = {
        enable = true;
        configurationLimit = 10;
        efiSupport = true;
        efiInstallAsRemovable = true;
        mirroredBoots = [
          {
            devices = ["nodev"];
            path = "/boot1";
          }
          {
            devices = ["nodev"];
            path = "/boot2";
          }
        ];
      };
    };
    zfs = {
      extraPools = ["tank"];
      requestEncryptionCredentials = false;
    };
    tmp.useTmpfs = true;
    kernelParams = [
      "i915.enable_fbc=1"
      "zfs.l2arc_noprefetch=0"
      "zfs.l2arc_write_max=536870912"
      "zfs.l2arc_write_boost=1073741824"
    ];
    binfmt.emulatedSystems = ["aarch64-linux"];
  };

  systemd.network.links."11-default" = {
    matchConfig.OriginalName = "*";
    linkConfig.NamePolicy = "mac";
    linkConfig.MACAddressPolicy = "persistent";
  };

  networking = {
    hostName = "elena";
    hostId = "fc172604";

    vlans.vlan40 = {
      id = 40;
      interface = "br0";
    };

    # Home LAN, IPoE uplink
    bridges.br0.interfaces = [iface];
    interfaces.br0 = {
      macAddress = secrets.network.home.hosts.elena.macAddress;
      ipv4.addresses = [
        {
          address = secrets.network.home.hosts.elena.address;
          prefixLength = 24;
        }
      ];
    };

    interfaces.vlan40 = {
      ipv4.addresses = [
        {
          address = secrets.network.iot.hosts.elena.address;
          prefixLength = 24;
        }
      ];
    };

    interfaces."${ifaceStorage}" = {
      mtu = 9000;
      ipv4.addresses = [
        {
          address = secrets.network.storage.hosts.elena.address;
          prefixLength = 24;
        }
      ];
    };

    defaultGateway = secrets.network.home.defaultGateway;
    nameservers = secrets.network.home.nameserversAdguard;
  };

  localModules = {
    docker = {
      enable = true;
      useLocalDns = true;
    };

    pikvm.enable = true;

    scrutinyCollector = {
      enable = true;
      config.commands = {
        # Don't scan spun down drives
        metrics_info_args = "--info --json --nocheck=standby";
        metrics_smart_args = "--xall --json --nocheck=standby";
      };
      timerConfig = {
        OnCalendar = "*-*-* 01:10:00";
        RandomizedDelaySec = 0;
      };
    };

    vfio = {
      enable = true;
      cpuType = "intel";
    };

    virtwold = {
      enable = true;
      interfaces = ["br0"];
    };

    zfs.enable = true;
  };

  services.xserver.videoDrivers = ["modesetting"];

  virtualisation.libvirtd.enable = true;

  systemd.timers.update-mam = {
    wantedBy = ["timers.target"];
    partOf = ["update-mam.service"];
    after = ["network-online.target"];
    wants = ["network-online.target"];
    timerConfig = {
      OnCalendar = "0/2:00";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
  };

  systemd.services.update-mam = {
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = "/storage/appdata/scripts/mam";
      ExecStart = "/storage/appdata/scripts/mam/update_mam.sh";
    };
  };
}
