{
  config,
  pkgs,
  ...
}: {
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
    hostName = "vps-oci2";
    interfaces.ens3.useDHCP = true;
  };

  localModules = {
    backup = {
      enable = true;
      paths = [
        "/home"
        "/storage/appdata"
        "/var/lib/nixos"
        "/var/lib/tailscale"
        "/var/lib/traefik"
      ];
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
        adguardhome = {
          enable = true;
          dnsListenAddress = "127.0.0.1";
          dnsPort = 5300;
        };
        uptime-kuma.enable = true;
      };
      # TODO: Set hosts in each container module
      containers.adguardhome.proxies = {
        adguard.hosts = config.lib.containers.mkHosts {
          name = "adguard";
          unqualified = false;
        };
        adguardhome-admin.hosts = config.lib.containers.mkHosts {
          name = "adguardhome-admin";
          unqualified = false;
        };
      };
    };

    coredns = {
      enable = true;
      upstreamDns = "127.0.0.1:5300";
    };
  };

  # TailScale incorrectly detects resolved DNS mode and fails to set up MagicDNS.
  services.resolved.enable = true;
}
