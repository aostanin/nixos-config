{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./kvmd.nix
    ./meshcentral.nix
  ];

  networking = {
    hostName = "pikvm";
    useDHCP = true;
  };

  localModules = {
    traefik.enable = true;
    cloudflared.enable = true;

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

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
  ];
}
