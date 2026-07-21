{
  config,
  pkgs,
  lib,
  inputs,
  secrets,
  ...
}: {
  imports = [
    "${inputs.nixos-hardware}/lenovo/thinkpad/t440p"
    "${inputs.nixos-hardware}/common/pc/ssd"
    ./hardware-configuration.nix
    ./backup.nix
    ./litellm.nix
  ];

  boot = {
    loader = {
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        zfsSupport = true;
        configurationLimit = 10;
        mirroredBoots = [
          {
            devices = ["nodev"];
            path = "/boot1";
            efiSysMountPoint = "/boot1";
          }
          {
            devices = ["nodev"];
            path = "/boot2";
            efiSysMountPoint = "/boot2";
          }
        ];
      };
    };
    tmp.useTmpfs = true;
    blacklistedKernelModules = ["nouveau"];
    kernelParams = [
      "intel_iommu=on"
      "iommu=pt"
      "intel_pstate=active"
      "i915.enable_fbc=1"
      "zfs.zfs_arc_max=${toString (2 * 1024 * 1024 * 1024)}"
      "iomem=relaxed" # To flash firmware
    ];
    binfmt.emulatedSystems = ["aarch64-linux"];
  };

  networking = {
    hostName = "mareg";
    hostId = "393740af";
  };

  powerManagement.powertop.enable = true;

  localModules = {
    backup = {
      enable = true;
      paths = [
        "/home"
        "/persist/safe"
      ];
    };

    common.enable = true;

    home-router = {
      enable = true;
      interface = "enx${lib.replaceStrings [":"] [""] secrets.network.nics.mareg.integrated}";
      macAddress = secrets.network.home.hosts.mareg.macAddress;
    };

    ingress.adguard = {
      port = 3000;
      default.enable = true;
    };

    containers = {
      enable = true;
      storage = {
        default = "/persist/safe/appdata/containers/data";
        bulk = "/persist/safe/appdata/containers/bulk";
        temp = "/persist/cache/appdata/containers/temp";
      };
      services = {
        authelia.enable = true;
        forgejo.enable = true;
        guacamole.enable = true;
        netbootxyz.enable = true;
        nextcloud.enable = true;
        scrutiny.enable = true;
        syncthing.enable = true;
        unifi.enable = true;

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
      };
    };

    impermanence.enable = true;

    intelAmt.enable = true;

    nvtop.package = pkgs.nvtopPackages.intel;

    scrutinyCollector.enable = true;

    tailscale = {
      isServer = true;
      extraFlags = [
        "--advertise-exit-node"
        "--advertise-routes=${secrets.network.networks.iot.prefix}.0/24"
      ];
    };

    watchdog.enable = true;

    zfs.enable = true;
  };

  services = {
    logind.settings.Login.HandleLidSwitch = "ignore";

    tlp = {
      enable = true;
      settings = {
        USB_AUTOSUSPEND = 0;
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };
  };
}
