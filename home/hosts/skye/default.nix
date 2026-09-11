{
  pkgs,
  config,
  lib,
  secrets,
  inputs,
  ...
}: {
  localModules = {
    common.enable = true;

    desktop.enable = true;

    niri.workspaceOutputs = with secrets.monitors; {
      "1" = lg.name;
      "2" = dell.name;
      "3" = "eDP-1";
      "4" = lg.name;
      "5" = dell.name;
      "6" = "eDP-1";
      "7" = lg.name;
      "8" = lg.name;
      "9" = lg.name;
    };

    gaming.enable = true;
  };

  services.kanshi.settings = [
    {
      profile.name = "undocked";
      profile.outputs = [
        {
          criteria = "eDP-1";
          status = "enable";
          scale = 1.0;
          mode = "1920x1200";
          position = "0,0";
        }
      ];
    }
    {
      profile.name = "docked";
      profile.outputs = [
        {
          criteria = "eDP-1";
          status = "enable";
          scale = 1.0;
          mode = "1920x1200";
          position = "3440,1560";
        }
        {
          criteria = secrets.monitors.lg.name;
          status = "enable";
          scale = 1.0;
          mode = "3440x1440";
          position = "0,1440";
        }
        {
          criteria = secrets.monitors.dell.name;
          status = "enable";
          scale = 1.0;
          mode = "2560x1440";
          position = "440,0";
        }
      ];
    }
  ];
}
