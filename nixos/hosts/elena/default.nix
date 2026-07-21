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
    ./litellm.nix
    ./llama-cpp.nix
    ./vfio.nix
    ./libvirt
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

    attic = {
      enable = true;
      storageDir = "/storage/appdata/attic";
    };

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
        open-webui.enable = true;

        speaches = {
          enable = true;
          # Not enough VRAM
          enableNvidia = false;
        };

        grist.enable = true;

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

        neko = {
          enable = true;
          devices = ["/dev/dri/renderD128"];
        };

        martin.enable = true;
        valhalla = {
          enable = true;
          pbfs = [
            "/storage/appdata/openstreetmap/regional/japan.osm.pbf"
            "/storage/appdata/openstreetmap/regional/kyrgyzstan.osm.pbf"
          ];
          forceRebuild = false;
          buildElevation = true;
        };
        overpass.enable = true;
        open-meteo = {
          enable = true;
          models = ["jma_msm" "dwd_icon"];
        };

        # Migrated from mareg
        archivebox.enable = true;
        changedetection.enable = true;
        forgejo.enable = true;
        guacamole.enable = true;
        karakeep.enable = true;
        mealie.enable = true;
        netbootxyz.enable = true;
        nextcloud.enable = true;
        scrutiny.enable = true;
        syncthing = {
          enable = true;
          # The native user syncthing owns 22000/21027.
          port = 22001;
          localDiscovery = false;
        };
        miniflux.enable = true;

        # Home automation (migrated from mareg)
        frigate = {
          enable = true;
          devices = [
            "/dev/bus/usb"
            "/dev/dri/renderD128"
          ];
        };
        home-assistant.enable = true;
        ir-mqtt-bridge.enable = true;
        mosquitto.enable = true;
        valetudopng.enable = true;
        zigbee2mqtt = {
          enable = true;
          adapterPath = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_5c9c4df6b1c9eb118d7d8b4f1d69213e-if00-port0";
        };

        # Voice assistant (migrated from mareg)
        openwakeword.enable = true;
        wyoming-openai = {
          enable = true;
          openaiUrl = "https://litellm.${secrets.domain}/v1";
          sttModels = ["whisper"];
          ttsModels = ["kokoro"];
          ttsVoices = ["af_heart" "bf_isabella" "jf_alpha"];
          languages = ["en" "ja"];
        };
        redlib = {
          inherit (secrets.redlib) subscriptions;
          enable = true;
        };
        searxng.enable = true;
        tasmoadmin.enable = true;
        vaultwarden.enable = true;
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
    logind.settings.Login.HandlePowerKey = "suspend";

    sunshine = {
      enable = true;
      capSysAdmin = true;
    };

    udev.packages = with pkgs; [openrgb];

    xserver.videoDrivers = ["modesetting" "nvidia"];
  };

  hardware.nvidia = {
    modesetting.enable = true;
    # TODO: Open has issues with VFIO
    # ref: https://www.reddit.com/r/VFIO/comments/xt5cdm/dmesg_shows_thousands_of_these_errors_ioremap/
    open = false;
    # FIXME: Workaround for nvidia-gpu 0000:01:00.3: Unable to change power state from D3hot to D0, device inaccessible
    powerManagement.finegrained = false;
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
      personal = {
        path = "/storage/personal";
        writable = "false";
        comment = "personal";
      };
    };
  };
}
