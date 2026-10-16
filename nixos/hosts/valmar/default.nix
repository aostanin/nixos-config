{
  config,
  pkgs,
  lib,
  inputs,
  secrets,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./backup.nix
    ./dev-container.nix
    ./libvirt
    ./llama-cpp.nix
    ./llama-swap.nix
    ./network.nix
    ./power-management.nix
    ./strata.nix
    ./vfio.nix
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
    binfmt.emulatedSystems = ["aarch64-linux"];
  };

  networking = {
    hostName = "valmar";
    hostId = "577514a9";
    firewall = {
      enable = true;
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        } # KDE Connect
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        } # KDE Connect
      ];
      interfaces.tailscale0 = {
        allowedTCPPorts = [
          22 # SSH
          22000 # Syncthing
        ];
        allowedUDPPorts = [
          5353 # Avahi
          22000 # Syncthing
          21027 # Syncthing
        ];
      };
    };
  };

  localModules = {
    backup = {
      enable = true;
      paths = [
        "/home"
        "/persist/safe"
      ];
      exclude = [
        "/home/*/.local/share/containers"
        "/home/*/.local/share/Steam/steamapps"
      ];
    };

    common.enable = true;

    desktop = {
      enable = true;
      enableGaming = true;
    };

    impermanence.enable = true;

    nvtop.package = pkgs.nvtopPackages.full;

    podman = {
      enable = true;
      enableAutoPrune = true;
    };

    tailscale = {
      isClient = true;
      extraFlags = [
        "--accept-routes"
        "--operator=${secrets.user.username}"
      ];
    };

    watchdog.enable = true;

    zfs.enable = true;
  };

  services.fwupd.enable = true;

  services.hardware.openrgb = {
    enable = true;
    motherboard = "intel";
  };
  # Lights off on every start; the Mystic Light controller has no Off mode. The
  # ARGB headers start with zero LEDs, so a color never reaches them unless they
  # are sized first, and a block with only a size makes the CLI bail out.
  systemd.services.openrgb.serviceConfig.ExecStart = let
    cfg = config.services.hardware.openrgb;
    off = zone: size:
      ["--device" "0" "--zone" (toString zone)]
      ++ lib.optionals (size != null) ["--size" (toString size)]
      ++ ["--mode" "static" "--color" "000000"];
  in
    lib.mkForce (lib.escapeShellArgs ([
        (lib.getExe cfg.package)
        "--server"
        "--server-port"
        cfg.server.port
      ]
      ++ off 0 null # JRGB1
      ++ off 1 30 # JRAINBOW1
      ++ off 2 30)); # JRAINBOW2
}
