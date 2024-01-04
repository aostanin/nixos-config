{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.localModules.intelAmt;
in {
  options.localModules.intelAmt = {
    enable = mkEnableOption "Intel AMT";
  };

  config = mkIf cfg.enable {
    # For SOL
    systemd.services."serial-getty@ttyS0" = {
      enable = true;
      serviceConfig = {
        Environment = "TERM=xterm-256color";
      };
    };
  };
}
