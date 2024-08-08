{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules.trayscale;
in {
  options.localModules.trayscale = {
    enable = lib.mkEnableOption "trayscale";
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.trayscale = {
      Unit = {
        Description = "trayscale";
        Wants = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe pkgs.trayscale} --hide-window";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
      Install = {WantedBy = ["graphical-session.target"];};
    };
  };
}
