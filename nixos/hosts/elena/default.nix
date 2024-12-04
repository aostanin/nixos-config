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
    kernelParams = [
      "zfs.l2arc_noprefetch=0"
      "zfs.l2arc_write_max=536870912"
      "zfs.l2arc_write_boost=1073741824"
      "zfs.zfs_arc_max=${toString (96 * 1024 * 1024 * 1024)}"
    ];
    binfmt.emulatedSystems = ["aarch64-linux"];
  };

  networking = {
    hostName = "elena";
    hostId = "fc172604";
  };

  localModules = {
    common.enable = true;

    containers = {
      enable = true;
      storage = {
        default = "/storage/appdata/docker/ssd";
        bulk = "/storage/appdata/docker/bulk";
        temp = "/storage/appdata/temp";
      };
      services = let
        uid = 1000;
        gid = 100;
      in {
        comfyui.enable = true;
        open-webui.enable = true;
        stable-diffusion.enable = true;

        meshcentral.enable = true;

        immich = {
          enable = true;
          uploadLocation = "/storage/personal/photos/sync/immich";
          volumes = [
            "/storage/personal/photos:/mnt/media/photos:ro"
            "/var/empty:/mnt/media/photos/sync/immich:ro"
          ];
          devices = [
            "/dev/dri/renderD128"
            "/dev/dri/card0"
          ];
        };

        jellyfin = {
          enable = true;
          inherit uid gid;
          volumes = ["/storage/media/videos:/srv/media/videos:ro"];
          devices = [
            "/dev/dri/renderD128"
            "/dev/dri/card0"
          ];
        };
        navidrome = {
          enable = true;
          volumes = ["/storage/media/music:/music:ro"];
        };
        xbvr = {
          enable = true;
          volumes = ["/storage/media/adult/vr:/videos"];
        };
        tdarr = {
          enable = true;
          inherit uid gid;
          volumes = ["/storage/media:/media"];
        };
        calibre-web = {
          enable = true;
          inherit uid gid;
          volumes = ["/storage/media/books:/books"];
        };
        komga = {
          enable = true;
          inherit uid gid;
          volumes = ["/storage/media/manga:/data"];
        };
        audiobookshelf = {
          enable = true;
          volumes = ["/storage/media/audiobooks:/audiobooks"];
        };

        nzbget = {
          enable = true;
          inherit uid gid;
          volumes = ["/storage/download/usenet:/downloads/usenet"];
        };
        qbittorrent = {
          enable = true;
          inherit uid gid;
          volumes = ["/storage/download/torrent:/downloads/torrent"];
        };
        lidarr = {
          enable = true;
          inherit uid gid;
          volumes = [
            "/storage/download/torrent:/downloads/torrent:ro"
            "/storage/download/usenet:/downloads/usenet"
            "/storage/media/music/auto:/music"
          ];
        };
        radarr = {
          enable = true;
          inherit uid gid;
          volumes = [
            "/storage/download/torrent:/downloads/torrent:ro"
            "/storage/download/usenet:/downloads/usenet"
            "/storage/media/videos/movies:/movies"
          ];
        };
        sonarr = {
          enable = true;
          inherit uid gid;
          volumes = [
            "/storage/download/torrent:/downloads/torrent:ro"
            "/storage/download/usenet:/downloads/usenet"
            "/storage/media/videos/tv:/tv"
          ];
        };
        prowlarr = {
          enable = true;
          inherit uid gid;
        };
        bazarr = {
          enable = true;
          inherit uid gid;
          volumes = [
            "/storage/media/videos/movies:/movies"
            "/storage/media/videos/tv:/tv"
          ];
        };
        jellyseerr.enable = true;
      };
    };

    desktop = {
      enable = true;
      enableGaming = true;
      preStartCommands = ''
        export WLR_DRM_DEVICES=$(readlink -f /dev/dri/by-path/pci-0000:00:02.0-card)
        export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json
      '';
    };

    forgejo-runner.enable = true;

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

  services.samba = {
    enable = true;
    nmbd.enable = false;
    winbindd.enable = false;
    openFirewall = true;
    settings = {
      global = {
        "acl allow execute always" = "yes";
      };
      media = {
        path = "/storage/media";
        writable = "false";
        comment = "media";
      };
    };
  };
}
