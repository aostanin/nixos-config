{
  pkgs,
  lib,
  secrets,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./kvmd.nix
    ./meshcentral.nix
  ];

  networking.hostName = "pikvm";

  localModules = {
    traefik.enable = true;
    cloudflared.enable = true;

    # Keepalived backup for the router VM (lower priority).
    home-router = {
      enable = true;
      interface = "enx${lib.replaceStrings [":"] [""] secrets.network.nics.pikvm.integrated}";
      macAddress = secrets.network.home.hosts.pikvm.macAddress;
      isMaster = false;
    };

    backup = {
      enable = true;
      paths = [
        "/var/lib/kvmd"
        "/var/lib/nixos"
        "/var/lib/tailscale"
        "/var/lib/meshcentral"
      ];
    };

    common = {
      enable = true;
      minimal = true;
    };

    tailscale = {
      isServer = true;
      advertiseExitNode = true;
    };
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
  ];
}
