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
    common.enable = true;

    docker.enable = true;
  };
}
