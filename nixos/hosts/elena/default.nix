{
  config,
  pkgs,
  lib,
  inputs,
  secrets,
  ...
}: {
  imports = [
    "${inputs.nixos-hardware}/common/cpu/intel"
    "${inputs.nixos-hardware}/common/pc/ssd"
    ./hardware-configuration.nix
    ./backup.nix
    ./backup-external.nix
    #./i915-sriov.nix
    ./vfio.nix
    ./power-management.nix
    ./autosuspend.nix
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
      extraPools = ["tank" "vmpool"];
      requestEncryptionCredentials = false;
    };
    tmp.useTmpfs = true;
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    kernelParams = [
      "zfs.l2arc_noprefetch=0"
      "zfs.l2arc_write_max=536870912"
      "zfs.l2arc_write_boost=1073741824"
    ];
    binfmt.emulatedSystems = ["aarch64-linux"];
  };

  networking = {
    hostName = "elena";
    hostId = "fc172604";
  };

  localModules = {
    common.enable = true;

    desktop = {
      enable = true;
      enableGaming = true;
      preStartCommands = ''
        export WLR_DRM_DEVICES=$(readlink -f /dev/dri/by-path/pci-0000:00:02.0-card)
        export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json
      '';
    };

    docker = {
      enable = true;
      useLocalDns = true;
    };

    forgejo-runner.enable = true;

    headlessGaming = {
      #enable = true;
      gpuBusId = "PCI:1:0:0";
    };

    home-server = {
      enable = true;
      interface = "enx${lib.replaceStrings [":"] [""] secrets.network.nics.elena.integrated}";
      address = secrets.network.home.hosts.elena.address;
      macAddress = secrets.network.home.hosts.elena.macAddress;
      iotNetwork = {
        enable = true;
        address = secrets.network.iot.hosts.elena.address;
      };
    };

    pikvm = {
      enable = true;
      # USB serial prevents PC6 C-State, maxes at PC2
      enableUsbSerial = false;
    };

    scrutinyCollector = {
      enable = true;
      config.commands = {
        # Don't scan spun down drives
        metrics_info_args = "--info --json --nocheck=standby";
        metrics_smart_args = "--xall --json --nocheck=standby";
      };
      timerConfig = {
        RandomizedDelaySec = 0;
        OnCalendar = "*-*-* 18:05:00";
      };
    };

    tailscale = {
      isClient = true;
      isServer = true;
    };

    virtwold = {
      enable = true;
      interfaces = ["br0"];
    };

    zfs.enable = true;
  };

  services = {
    logind.powerKey = "suspend";

    sunshine = {
      enable = true;
      capSysAdmin = true;
    };

    xserver.videoDrivers = ["modesetting" "nvidia"];
  };

  hardware.nvidia = {
    # TODO: Fixes issues with suspend. Remove once >555.58 is stable.
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "555.58";
      sha256_64bit = "sha256-bXvcXkg2kQZuCNKRZM5QoTaTjF4l2TtrsKUvyicj5ew=";
      sha256_aarch64 = "sha256-7XswQwW1iFP4ji5mbRQ6PVEhD4SGWpjUJe1o8zoXYRE=";
      openSha256 = "sha256-hEAmFISMuXm8tbsrB+WiUcEFuSGRNZ37aKWvf0WJ2/c=";
      settingsSha256 = "sha256-vWnrXlBCb3K5uVkDFmJDVq51wrCoqgPF03lSjZOuU8M=";
      persistencedSha256 = "sha256-lyYxDuGDTMdGxX3CaiWUh1IQuQlkI2hPEs5LI20vEVw=";
    };
    patch.enable = true;
    modesetting.enable = true;
    # TODO: Open has issues with VFIO
    # ref: https://www.reddit.com/r/VFIO/comments/xt5cdm/dmesg_shows_thousands_of_these_errors_ioremap/
    # open = true;
    powerManagement.finegrained = true;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

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
      ExecStartPre = "${lib.getExe' pkgs.coreutils "sleep"} 30"; # Network is offline when resuming from sleep
      ExecStart = "/storage/appdata/scripts/mam/update_mam.sh";
    };
  };
}
