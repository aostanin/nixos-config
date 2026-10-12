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
      "zfs.zfs_arc_max=${toString (4 * 1024 * 1024 * 1024)}"
    ];
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

    networkmanager.enable = true;

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

    zfs.enable = true;
  };

  services.fwupd.enable = true;
}
