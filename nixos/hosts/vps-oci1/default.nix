{
  config,
  pkgs,
  ...
}: let
  ntfyPort = 2586;
in {
  imports = [
    ./hardware-configuration.nix
  ];

  hardware.enableRedistributableFirmware = false;

  boot = {
    kernelParams = [
      "console=ttyS0,115200"
      "console=tty1"
    ];
    tmp.cleanOnBoot = true;
  };

  networking = {
    hostName = "vps-oci1";
    interfaces.ens3.useDHCP = true;
    firewall = {
      enable = true;
      trustedInterfaces = ["tailscale0"];
    };
  };

  localModules = {
    backup = {
      enable = true;
      paths = [
        "/home"
        "/storage/appdata"
        "/var/lib/nixos"
        "/var/lib/tailscale"
        "/var/lib/phoenixd"
        "/var/lib/traefik"
      ];
    };

    phoenixd.enable = true;

    ingress.ntfy = {
      port = ntfyPort;
      default.enable = false;
      trusted.enable = true;
    };

    common = {
      enable = true;
      minimal = true;
    };

    containers = {
      enable = true;
      storage = {
        default = "/storage/appdata/docker/ssd";
        bulk = "/storage/appdata/docker/bulk";
        temp = "/storage/appdata/temp";
      };
      services = {
        lnbits.enable = true;
      };
    };

    adguardhome.enable = true;

    traefik.dnsOverTls.enable = true;
  };

  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.${config.localModules.traefik.domain}";
      listen-http = "127.0.0.1:${toString ntfyPort}";
      behind-proxy = true;
    };
  };

  # TailScale incorrectly detects resolved DNS mode and fails to set up MagicDNS.
  services.resolved.enable = true;
}
