{
  config,
  pkgs,
  lib,
  hardwareModulesPath,
  secrets,
  ...
}: {
  imports = [
    "${hardwareModulesPath}/common/cpu/intel"
    "${hardwareModulesPath}/common/pc/ssd"
    ./hardware-configuration.nix
    ../../modules
    ../../modules/common
    ../../modules/msmtp
    ../../modules/zerotier
    ./backup.nix
    #./i915-sriov.nix
    ./vfio.nix
    ./power-management.nix
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
      "i915.enable_fbc=1"
    ];
    binfmt.emulatedSystems = ["aarch64-linux"];
  };

  networking = {
    hostName = "valmar";
    hostId = "4446d154";
  };

  localModules = {
    desktop = {
      enable = true;
      primaryOutput = "HDMI-A-1";
      output = {
        "*" = {
          bg = "~/Sync/wallpaper/nix-wallpaper-nineish-dark-gray.png fill";
        };
        "HDMI-A-1" = {
          pos = "0,1440";
        };
        "DP-1" = {
          pos = "440,0";
        };
      };
      preStartCommands = ''
        export WLR_DRM_DEVICES=$(readlink -f /dev/dri/by-path/pci-0000:00:02.0-card)
        export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json
      '';
      workspaceOutputAssign = builtins.map (x: {
        workspace = builtins.toString x;
        output =
          if (lib.mod x 2) == 1
          then "HDMI-A-1"
          else "DP-1";
      }) [1 2 3 4 5 6 7 8 9];
    };

    docker = {
      enable = true;
      useLocalDns = true;
    };

    home-server = {
      enable = true;
      interface = "enx${lib.replaceStrings [":"] [""] secrets.network.nics.valmar.expansion10GbE0}";
      address = secrets.network.home.hosts.valmar.address;
      macAddress = secrets.network.home.hosts.valmar.macAddress;
      iotNetwork = {
        enable = true;
        address = secrets.network.iot.hosts.valmar.address;
      };
      storageNetwork = {
        enable = true;
        address = secrets.network.iot.hosts.valmar.address;
      };
    };

    pikvm.enable = true;

    scrutinyCollector.enable = true;

    virtwold = {
      enable = true;
      interfaces = ["br0"];
    };

    zfs.enable = true;
  };

  services = {
    logind.extraConfig = ''
      HandlePowerKey=suspend
    '';

    xserver.videoDrivers = ["modesetting" "nvidia"];
  };

  virtualisation = {
    libvirtd.enable = true;

    waydroid.enable = true;
  };

  fileSystems."/mnt/elena" = {
    device = "${secrets.network.storage.hosts.elena.address}:/";
    fsType = "nfs";
    options = ["x-systemd.automount" "x-systemd.idle-timeout=600" "noauto" "noatime"];
  };
}
