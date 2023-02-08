{
  config,
  pkgs,
  ...
}: let
  secrets = import ../../secrets;
in {
  imports = [
    ./hardware-configuration.nix
    ../../modules/variables
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

  boot.cleanTmpDir = true;

  networking = {
    hostName = "vps-oci2";
    interfaces.ens3.useDHCP = true;
  };

  virtualisation.docker = {
    enable = true;
    liveRestore = false;
    autoPrune = {
      # Don't autoprune on servers
      enable = false;
      flags = [
        "--all"
        "--filter \"until=168h\""
      ];
    };
  };
}
