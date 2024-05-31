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
  };

  boot.tmp.cleanOnBoot = true;

  networking = {
    hostName = "vps-oci1";
    interfaces.ens3.useDHCP = true;
  };

  localModules = {
    common.enable = true;

    docker.enable = true;
  };
}
