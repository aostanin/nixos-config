{
  config,
  pkgs,
  lib,
  inputs,
  secrets,
  ...
}: let
  uid = 1000;
  gid = 100;
in {
  imports = [
    "${inputs.nixos-hardware}/common/pc/ssd"
    ./hardware-configuration.nix
    ./backup.nix
    ./backup-external.nix
    ./incus.nix
    ./litellm.nix
    ./actual.nix
    ./n8n.nix
    ./silverbullet.nix
    ./llama-cpp.nix
    ./whisper-cpp.nix
    ./kokoro-fastapi.nix
    ./redlib.nix
    ./microvm.nix
    ./power-management.nix
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
      "zfs.zfs_arc_max=4294967296"
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
      services = {
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
        manyfold = {
          enable = true;
          inherit uid gid;
          volumes = ["/storage/personal/files/3D Printer/things:/models"];
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

        archivebox.enable = true;
        authelia.enable = true;
        changedetection.enable = true;
        endurain.enable = true;
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

        # Voice assistant
        openwakeword.enable = true;
        wyoming-openai = {
          enable = true;
          openaiUrl = "https://litellm.${secrets.domain}/v1";
          sttModels = ["whisper"];
          ttsModels = ["kokoro"];
          ttsVoices = ["af_heart" "bf_isabella" "jf_alpha"];
          languages = ["en" "ja"];
        };
        searxng.enable = true;
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

  roles.downloads = {
    enable = true;
    inherit uid gid;
    downloadDir = "/storage/download";
    movieDir = "/storage/media/videos/movies";
    tvDir = "/storage/media/videos/tv";
    musicDir = "/storage/media/music/auto";
  };

  roles.home-automation = {
    enable = true;
    zigbeeAdapter = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_5c9c4df6b1c9eb118d7d8b4f1d69213e-if00-port0";
    frigateDevices = [
      "/dev/bus/usb"
      "/dev/dri/renderD128"
    ];
  };

  services = {
    logind.settings.Login.HandlePowerKey = "suspend";

    xserver.videoDrivers = ["modesetting" "nvidia"];
  };

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    # 26.05's 595.71.05 calls strncpy, which 7.x no longer provides. Unstable's
    # driver definitions, built against this kernel.
    package =
      (config.boot.kernelPackages.callPackage "${inputs.nixpkgs-unstable}/pkgs/os-specific/linux/nvidia-x11" {}).production;
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
