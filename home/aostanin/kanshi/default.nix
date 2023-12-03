{
  pkgs,
  config,
  lib,
  secrets,
  ...
}: {
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
            mode = "1920x1200";
            position = "3440,1560";
          }
          {
            criteria = secrets.monitors.lg.name;
            status = "enable";
            mode = "3440x1440";
            position = "0,1440";
          }
          {
            criteria = secrets.monitors.dell.name;
            status = "enable";
            mode = "2560x1440";
            position = "440,0";
          }
        ];
      };
    };
  };
}
