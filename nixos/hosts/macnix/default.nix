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
  };

  networking = {
    hostName = "macnix";
    hostId = "a1b2c3d4";
  };

  localModules = {
    common.enable = true;

    desktop.enable = true;

    networkmanager.enable = true;

    podman = {
      enable = true;
      enableAutoPrune = true;
    };

    tailscale = {
      isClient = true;
      extraFlags = [
        "--operator=${secrets.user.username}"
      ];
    };
  };

  services.spice-vdagentd.enable = true;
}
