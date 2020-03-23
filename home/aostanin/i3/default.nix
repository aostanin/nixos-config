{ pkgs, config, lib, ... }:

with lib;

{
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      modifier = "Mod4";
      focus.followMouse = false;
      keybindings =
        let modifier = config.xsession.windowManager.i3.config.modifier;
        in mkOptionDefault {
          "${modifier}+d" = "exec ${pkgs.rofi}/bin/rofi -show combi";
        };
      bars = [ {
        trayOutput = "primary";
      } ];
    };
    extraConfig = ''
      exec --no-startup-id xset dpms 600
      exec --no-startup-id ${pkgs.autorandr}/bin/autorandr --change
      exec --no-startup-id ${pkgs.networkmanagerapplet}/bin/nm-applet --sm-disable
      exec --no-startup-id ${pkgs.pasystray}/bin/pasystray
      exec --no-startup-id ${pkgs.barrier}/bin/barrier
      exec --no-startup-id ${pkgs.syncthing-gtk}/bin/syncthing-gtk --minimized

      for_window [class="mpv"] floating enable border none
      for_window [class=".*scrcpy.*"] floating enable border none
    '';
  };

  home.packages = with pkgs; [
    arandr
    pavucontrol
  ];

  programs = {
    rofi = {
      enable = true;
      theme = "gruvbox-dark";
      extraConfig = ''
        rofi.modi: window,drun,run,ssh,combi
        rofi.combi-modi: window,drun,ssh
        rofi.show-icons: true
      '';
    };
  };

  services = {
    compton = {
      enable = true;
    };

    kdeconnect = {
      enable = true;
      indicator = true;
    };

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
