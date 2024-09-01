{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  boot = {
    tmp.cleanOnBoot = true;
  };

  networking = {
    hostName = "vps-oci-arm1";
    hostId = "1da26099";
    interfaces.enp0s6.useDHCP = true;
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
        whoami.enable = true;
      };
    };

    forgejo-runner.enable = true;
  };

  # TailScale incorrectly detects resolved DNS mode and fails to set up MagicDNS.
  services.resolved.enable = true;
}
