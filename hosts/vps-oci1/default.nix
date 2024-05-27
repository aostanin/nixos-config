{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
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
