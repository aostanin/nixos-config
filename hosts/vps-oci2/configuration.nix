{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../../modules/common
    ../../modules/msmtp
    ../../modules/zerotier
  ];

  boot = {
    kernelParams = [
      "console=ttyS0,115200"
      "console=tty1"
    ];
  };

  boot.tmp.cleanOnBoot = true;

  networking = {
    hostName = "vps-oci2";
    interfaces.ens3.useDHCP = true;
  };

  localModules.docker.enable = true;
}
