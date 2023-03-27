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
    hostName = "vps-oci1";
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

  systemd = {
    # Matrix LINE bridge can be a bit unstable, so restart it daily
    timers.restart-line-bridge = {
      wantedBy = ["timers.target"];
      partOf = ["restart-line-bridge.service"];
      timerConfig = {
        OnCalendar = "*-*-* 02:00:00";
        Persistent = true;
        RandomizedDelaySec = "15m";
      };
    };
    services.restart-line-bridge = {
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.docker}/bin/docker stop matrix-puppeteer-line matrix-puppeteer-line-chrome
        sleep 10
        ${pkgs.docker}/bin/docker start matrix-puppeteer-line matrix-puppeteer-line-chrome
      '';
    };
  };
}
