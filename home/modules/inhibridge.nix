{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules.inhibridge;
in {
  options.localModules.inhibridge = {
    enable = lib.mkEnableOption "inhibridge";
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.inhibridge = {
      Unit = {
        Description = "inhibridge";
        Wants = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe pkgs.inhibridge}";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
      Install = {WantedBy = ["graphical-session.target"];};
    };
  };
}
