{
  pkgs,
  lib,
  secrets,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./kvmd.nix
    ./meshcentral.nix
  ];

  networking.hostName = "pikvm";

  # Reuse the RPi kernel kvmd.nix's CI builds and caches
  boot.kernelPackages = lib.mkForce inputs.kvmd.nixosConfigurations.v2-hdmi-rpi4.config.boot.kernelPackages;

  localModules = {
    traefik.enable = true;
    cloudflared.enable = true;

    # Keepalived backup router for mareg (lower priority).
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
      extraFlags = ["--advertise-exit-node"];
    };
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
  ];
}
