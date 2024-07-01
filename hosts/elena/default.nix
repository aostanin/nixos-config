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
    ./nfs.nix
    ./vfio.nix
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
      extraPools = ["tank" "vmpool"];
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

  networking = {
    hostName = "elena";
    hostId = "fc172604";

    # Using ConnectX-3, networking doesn't come back up after sleep without this
    useNetworkd = true;
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

    headlessGaming = {
      #enable = true;
      gpuBusId = "PCI:1:0:0";
    };

    home-server = {
      enable = true;
      interface = "enx${lib.replaceStrings [":"] [""] secrets.network.nics.elena.expansion10GbE0}";
      address = secrets.network.home.hosts.elena.address;
      macAddress = secrets.network.home.hosts.elena.macAddress;
      iotNetwork = {
        enable = true;
        address = secrets.network.iot.hosts.elena.address;
      };
      storageNetwork = {
        enable = true;
        address = secrets.network.storage.hosts.elena.address;
      };
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
        RandomizedDelaySec = 0;
        OnCalendar = "*-*-* 18:05:00";
      };
    };

    tailscale = {
      isClient = true;
      isServer = true;
      extraSetFlags = [
        "--advertise-exit-node"
        "--advertise-routes=10.0.40.0/24"
      ];
    };

    virtwold = {
      enable = true;
      interfaces = ["br0"];
    };

    zfs.enable = true;
  };

  services = {
    autosuspend = {
      enable = true;
      settings = {
        interval = 30;
        idle_time = 1800;
        # The default can't find echo
        wakeup_cmd = let
          echo = lib.getExe' pkgs.coreutils "echo";
        in "${lib.getExe pkgs.bash} -c '${echo} 0 > /sys/class/rtc/rtc0/wakealarm && ${echo} {timestamp:.0f} > /sys/class/rtc/rtc0/wakealarm'";
      };
      checks = {
        ActiveConnection.ports = lib.concatStringsSep "," [
          "22" # ssh
          "8888" # zrepl
          "8889" # zrepl
        ];
        LogindSessionsIdle = {};
        Processes.processes = lib.concatStringsSep "," [
          "mosh-server"
          "rsync"
        ];
        navidrome = {
          class = "ExternalCommand";
          command = let
            baseUrl = secrets.navidrome.baseUrl;
            username = secrets.navidrome.username;
            password = secrets.navidrome.password;
          in
            toString (pkgs.writeShellScript "check_navidrome_playing" ''
              response=$(${lib.getExe pkgs.curl} -s "${baseUrl}/rest/getNowPlaying.view?u=${username}&p=${password}&v=1.15.&c=curl")
              echo $response | ${lib.getExe' pkgs.yq "xq"} -e '."subsonic-response".nowPlaying != null'
            '');
        };
        jellyfin = {
          class = "ExternalCommand";
          command = let
            baseUrl = secrets.jellyfin.baseUrl;
            token = secrets.jellyfin.token;
          in
            toString (pkgs.writeShellScript "check_jellyfin_sessions" ''
              sessions=$(${lib.getExe pkgs.curl} -s ${baseUrl}/sessions?api_key=${token})
              echo $sessions | ${lib.getExe pkgs.jq} -e '. | map(select(.NowPlayingItem != null)) != []'
            '');
        };
        qbittorrent = {
          class = "ExternalCommand";
          command = let
            baseUrl = secrets.qbittorrent.baseUrl;
            username = secrets.qbittorrent.username;
            password = secrets.qbittorrent.password;
          in
            toString (pkgs.writeShellScript "check_qbittorrent_downloads" ''
              SID=$(${lib.getExe pkgs.curl} -s -o /dev/null -c - --data "username=${username}&password=${password}" "${baseUrl}/api/v2/auth/login" | ${lib.getExe pkgs.gawk} 'END{print $NF}')
              torrents=$(${lib.getExe pkgs.curl} -s --cookie "SID=$SID" --data "filter=downloading&sort=dlspeed&reverse=true&limit=1" "${baseUrl}/api/v2/torrents/info")
              echo $torrents | ${lib.getExe pkgs.jq} -e '.[].dlspeed > 1000'
            '');
        };
        tdarr = {
          class = "ExternalCommand";
          command = let
            baseUrl = secrets.tdarr.baseUrl;
            username = secrets.tdarr.username;
            password = secrets.tdarr.password;
          in
            toString (pkgs.writeShellScript "check_tdarr" ''
              nodes=$(${lib.getExe pkgs.curl} -s -u "${username}:${password}" ${baseUrl}/api/v2/get-nodes)
              echo $nodes | ${lib.getExe pkgs.jq} -e '.[].workers | to_entries | map(select(.value.idle == false)) != []'
            '');
        };
        vms = {
          class = "ExternalCommand";
          command = toString (pkgs.writeShellScript "check_running_vms" ''
            status=$(${lib.getExe' pkgs.libvirt "virsh"} -q list --state-running | grep "running")
            if [ -z "$status" ]; then
              exit 1
            else
              exit 0
            fi
          '');
        };
        zfs = {
          class = "ExternalCommand";
          command = let
            zfsUser = config.boot.zfs.package;
          in
            toString (pkgs.writeShellScript "check_zfs" ''
              status=$(${lib.getExe' zfsUser "zpool"} status | grep "scrub in progress")
              if [ -z "$status" ]; then
                exit 1
              else
                exit 0
              fi
            '');
        };
      };
      wakeups = {
        backup_external = {
          class = "SystemdTimer";
          match = "zrepl-local-push.timer";
        };
      };
    };

    logind.extraConfig = ''
      HandlePowerKey=suspend
    '';

    xserver.videoDrivers = ["modesetting" "nvidia"];
  };

  hardware.nvidia = {
    # TODO: Fixes issues with suspend. Remove once 555.58 is availale in stable/unstable.
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
