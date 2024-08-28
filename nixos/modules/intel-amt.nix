{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.localModules.intelAmt;
in {
  options.localModules.intelAmt = {
    enable = lib.mkEnableOption "Intel AMT";
  };

  config = lib.mkIf cfg.enable {
    # For SOL
    systemd.services."serial-getty@ttyS0" = {
      enable = true;
      serviceConfig = {
        Environment = "TERM=xterm-256color";
        Restart = "always";
      };
    };

    services.udev.extraRules = ''
      KERNEL=="ttyS0", TAG+="systemd", ENV{SYSTEMD_WANTS}="serial-getty@%k.service"
    '';
  };
}
