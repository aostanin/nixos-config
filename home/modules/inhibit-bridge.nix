{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules.inhibit-bridge;
in {
  options.localModules.inhibit-bridge = {
    enable = lib.mkEnableOption "inhibit-bridge";
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.inhibit-bridge = {
      Unit = {
        Description = "inhibit-bridge";
        Wants = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe pkgs.inhibit-bridge} -verbose";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
      Install = {WantedBy = ["graphical-session.target"];};
    };
  };
}
