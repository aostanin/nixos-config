{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

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
    common = {
      enable = true;
      minimal = true;
    };

    containers = {
      enable = true;
      storage = {
        default = "/storage/appdata/docker/ssd";
        bulk = "/storage/appdata/docker/bulk";
      };
      services = {
        adguardhome = {
          enable = true;
          dnsListenAddress = "127.0.0.1";
          dnsPort = 5300;
        };
        mealie.enable = true;
        miniflux.enable = true;
        uptime-kuma.enable = true;
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
