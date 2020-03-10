{ pkgs, config, lib, ... }:

with lib;

{
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      modifier = "Mod4";
      # TODO: Not supported on 19.09
      # terminal = "konsole";
      focus.followMouse = false;
      keybindings =
        let modifier = config.xsession.windowManager.i3.config.modifier;
        in mkOptionDefault {
          "${modifier}+Return" = "exec konsole";
          "${modifier}+d" = "exec ${pkgs.rofi}/bin/rofi -show combi";
        };
      bars = [ {
        trayOutput = "primary";
      } ];
    };
    extraConfig = ''
      exec --no-startup-id ${pkgs.nitrogen}/bin/nitrogen --restore
      exec --no-startup-id ${pkgs.networkmanagerapplet}/bin/nm-applet --sm-disable
    '';
  };

  programs = {
    rofi = {
      enable = true;
      theme = "glue_pro_blue";
      extraConfig = ''
        rofi.modi: window,drun,run,ssh,combi
        rofi.combi-modi: window,drun,ssh
      '';
    };
  };

  services = {
    kdeconnect = {
      enable = true;
      indicator = true;
    };
  };
}
