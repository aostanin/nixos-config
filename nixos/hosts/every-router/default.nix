{
  config,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./backup.nix
    ./home-assistant.nix
    ./kernel.nix
    ./network.nix
    ./router.nix
    ./power-management.nix
    ./wlan.nix
    ./wwan.nix
  ];

  networking.hostName = "every-router";

  localModules = {
    common = {
      enable = true;
      minimal = true;
    };

    # FIXME: When cloudflared is enabled, all network traffic breaks when Starlink is disconnected
    # cloudflared.enable = true;

    tailscale = {
      isServer = true;
      extraFlags = [
        "--advertise-exit-node"
        "--advertise-routes=10.0.50.0/24"
      ];
    };

    traefik.enable = true;
  };

  # TODO: Change default gateway based on if Starlink is actually connected

  services.traefik.dynamicConfigOptions = {
    http.routers.home-assistant = {
      rule = "Host(`every.${config.localModules.containers.domain}`)";
      entrypoints = "websecure";
      service = "home-assistant";
    };
    http.services.home-assistant.loadbalancer.servers = [
      {url = "http://127.0.0.1:8123";}
    ];
  };
}
