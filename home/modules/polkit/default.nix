{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules.polkit;
in {
  options.localModules.polkit = {
    enable = lib.mkEnableOption "polkit";
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      Unit = {
        Description = "polkit-gnome-authentication-agent-1";
        Wants = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
      Install = {WantedBy = ["graphical-session.target"];};
    };
  };
}
