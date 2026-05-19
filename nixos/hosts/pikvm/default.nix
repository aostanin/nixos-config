{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./kvmd.nix
  ];

  networking = {
    hostName = "pikvm";
    useDHCP = true;
  };

  localModules = {
    backup = {
      enable = true;
      paths = [
        "/var/lib/kvmd"
        "/var/lib/nixos"
        "/var/lib/tailscale"
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
