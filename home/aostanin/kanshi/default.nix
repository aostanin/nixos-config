{
  pkgs,
  config,
  lib,
  ...
}: let
  secrets = import ../../../secrets;
in {
  services.kanshi = {
    enable = true;
    profiles = {
      undocked = {
        outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
          }
        ];
      };
      docked = {
        outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
            position = "3440,180";
          }
          {
            criteria = secrets.monitors.lg.name;
            status = "enable";
            mode = "3440x1440";
            position = "0,0";
          }
        ];
      };
    };
  };
}
