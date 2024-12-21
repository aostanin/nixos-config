{
  config,
  pkgs,
  lib,
  inputs,
  secrets,
  ...
}: let
  interface = "enx${lib.replaceStrings [":"] [""] secrets.network.nics.roan.integrated}";
in {
  imports = [
    "${inputs.nixos-hardware}/lenovo/thinkpad/x250"
    "${inputs.nixos-hardware}/common/pc/laptop/ssd"
    ./hardware-configuration.nix
    ./backup.nix
  ];

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
    };
    tmp.useTmpfs = true;
    kernelParams = [
      "intel_iommu=on"
      "iommu=pt"
      "intel_pstate=active"
      "i915.enable_fbc=1"
      "zfs.zfs_arc_max=${toString (2 * 1024 * 1024 * 1024)}"
      "msr.allow_writes=on" # For undervolt
    ];
    binfmt.emulatedSystems = ["aarch64-linux"];
  };

  networking = {
    hostName = "roan";
    hostId = "9bc52069";
    localCommands = ''
      # Avoid hang when traffic is high
      # ref: https://forums.servethehome.com/index.php?threads/fix-intel-i219-v-detected-hardware-unit-hang.36700/#post-339318
      ${lib.getExe pkgs.ethtool} -K ${interface} tso off gso off
    '';
  };

  powerManagement.powertop.enable = true;

  localModules = {
    backup = {
      enable = true;
      paths = [
        "/home"
        "/storage/appdata"
        "/var/lib/libvirt"
        "/var/lib/nixos"
        "/var/lib/tailscale"
        "/var/lib/traefik"
      ];
    };

    common.enable = true;

    coredns = {
      enable = true;
      upstreamDns = "127.0.0.1:5300";
      enableLan = true;
      additionalBindInterfaces = ["br0"];
    };

    containers = {
      enable = true;
      storage = {
        default = "/storage/appdata/docker/ssd";
        bulk = "/storage/appdata/docker/bulk";
        temp = "/storage/appdata/temp";
      };
      services = {
        adguardhome = {
          enable = true;
          dnsListenAddress = "127.0.0.1";
          dnsPort = 5300;
        };
        adguardhome-sync.enable = true;
        archivebox.enable = true;
        authelia.enable = true;
        changedetection.enable = true;
        dawarich.enable = true;
        forgejo.enable = true;
        guacamole.enable = true;
        hauk.enable = true;
        invidious.enable = true;
        jobcan.enable = true;
        netbootxyz.enable = true;
        ollama.enable = true;
        redlib = {
          inherit (secrets.redlib) subscriptions;
          enable = true;
        };
        scrutiny.enable = true;
        searxng.enable = true;
        syncthing.enable = true;
        tasmoadmin.enable = true;
        unifi.enable = true;
        vaultwarden.enable = true;

        grafana.enable = true;
        influxdb.enable = true;

        # Home automation
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
        zwift-offline.enable = true;

        # Voice assistant
        piper.enable = true;
        whisper.enable = true;
        openwakeword.enable = true;
      };
    };

    home-server = {
      enable = true;
      interface = interface;
      address = secrets.network.home.hosts.roan.address;
      macAddress = secrets.network.home.hosts.roan.macAddress;
      iotNetwork = {
        enable = true;
        address = secrets.network.iot.hosts.roan.address;
      };
    };

    intelAmt.enable = true;

    nvtop.package = pkgs.nvtopPackages.intel;

    scrutinyCollector.enable = true;

    tailscale = {
      isServer = true;
      extraFlags = [
        "--advertise-exit-node"
        "--advertise-routes=10.0.40.0/24"
      ];
    };

    zfs.enable = true;
  };

  services = {
    logind.lidSwitch = "ignore";

    tlp = {
      enable = true;
      settings = {
        START_CHARGE_THRESH_BAT0 = 85;
        STOP_CHARGE_THRESH_BAT0 = 90;
        START_CHARGE_THRESH_BAT1 = 85;
        STOP_CHARGE_THRESH_BAT1 = 90;
      };
    };

    undervolt = {
      enable = true;
      coreOffset = -40;
      gpuOffset = -30;
    };
  };

  virtualisation.libvirtd.enable = true;
}
