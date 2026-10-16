{
  config,
  pkgs,
  lib,
  inputs,
  secrets,
  ...
}: {
  imports = [
    "${inputs.nixos-hardware}/common/pc/ssd"
    ./hardware-configuration.nix
    ./backup.nix
    ./backup-external.nix
    ./containers.nix
    ./incus.nix
    ./litellm.nix
    ./actual.nix
    ./n8n.nix
    ./silverbullet.nix
    ./llama-cpp.nix
    ./whisper-cpp.nix
    ./kokoro-fastapi.nix
    ./microvm.nix
    ./power-management.nix
    ./autosuspend.nix
    ./fan2go.nix
  ];

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
    };
    zfs = {
      extraPools = ["tank"];
      requestEncryptionCredentials = false;
    };
    tmp.useTmpfs = true;
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
        open-webui = {
          enable = true;
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
          devices = ["/dev/dri/renderD128"];
        };

        jellyfin = {
          enable = true;
          inherit uid gid;
          volumes = ["/storage/media/videos:/srv/media/videos:ro"];
          devices = ["/dev/dri/renderD128"];
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

        domi.enable = true;
        mymcp.enable = true;
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
        authelia.enable = true;
        changedetection.enable = true;
        forgejo.enable = true;
        guacamole.enable = true;
        karakeep.enable = true;
        mealie.enable = true;
        netbootxyz.enable = true;
        paseo-hub.enable = true;
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
        daikin-cleaner-mqtt.enable = true;
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
        unifi.enable = true;
        vaultwarden.enable = true;
      };
    };

    forgejo-runner.enable = true;

    home-server = {
      enable = true;
      interface = "enx${lib.replaceStrings [":"] [""] secrets.network.nics.elena.expansion10GbE0}";
      inherit (secrets.network.home.hosts.elena) address macAddress;
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

    tailscale.isClient = true;

    watchdog.enable = true;

    zfs.enable = true;
  };

  services = {
    logind.settings.Login.HandlePowerKey = "suspend";

    xserver.videoDrivers = ["modesetting" "nvidia"];
  };

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaPersistenced = true;
    powerManagement.enable = true;
  };

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
