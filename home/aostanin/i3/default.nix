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
      exec --no-startup-id ${pkgs.pasystray}/bin/pasystray

      for_window [class="mpv"] floating enable; border none
    '';
  };

  home.packages = with pkgs; [
    arandr
  ];

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
    compton = {
      enable = true;
    };

    dunst = {
      enable = true;
    };

    kdeconnect = {
      enable = true;
      indicator = true;
    };

    # TODO: Not supported on 19.09
    # grobi = {
    #   enable = true;
    #   rules = [
    #     {
    #       name = "Desktop";
    #       outputs_connected = [ "HDMI2" ];
    #       outputs_absent = [ "eDP-1" ];
    #       configure_single = "HDMI2";
    #       # TODO: Disable lock?
    #     }
    #     {
    #       name = "Laptop Docked Home";
    #       outputs_connected = [ "eDP-1" "DP-2-1" ];
    #       configure_row = [ "DP-2-1" "eDP-1" ];
    #       primary = [ "DP-2-1" ];
    #       # TODO: Disable lock?
    #     }
    #     {
    #       name = "Laptop Mobile";
    #       ouputs_disconnected = [ "DP-2-1" ];
    #       configure_single = "eDP-1";
    #     }
    #   ];
    # };

    redshift = {
      enable = true;
      provider = "geoclue2";
      tray = true;
      temperature = {
        day = 6500;
        night = 3000;
      };
    };

    screen-locker = {
      enable = true;
      inactiveInterval = 10;
    };

    udiskie = {
      enable = true;
      automount = false;
      tray = "always";
    };
  };
}
