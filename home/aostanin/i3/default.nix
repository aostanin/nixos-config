sysconfig:
{ pkgs, config, lib, ... }:

with lib;
let
  rofiWithPlugins = with pkgs; rofi.override {
    plugins = [
      rofi-calc
    ];
  };
in
{
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      modifier = "Mod4";
      focus.followMouse = false;
      keybindings =
        let
          modifier = config.xsession.windowManager.i3.config.modifier;
        in
        mkOptionDefault {
          "Print" = "exec ${pkgs.flameshot}/bin/flameshot gui";
          "${modifier}+d" = "exec ${pkgs.rofi}/bin/rofi -show combi";
          "${modifier}+c" = "exec ${rofiWithPlugins}/bin/rofi -show calc -modi calc -no-show-match -no-sort";
          "${modifier}+h" = "focus left";
          "${modifier}+j" = "focus down";
          "${modifier}+k" = "focus up";
          "${modifier}+l" = "focus right";
          "${modifier}+Shift+h" = "move left";
          "${modifier}+Shift+j" = "move down";
          "${modifier}+Shift+k" = "move up";
          "${modifier}+Shift+l" = "move right";
          "${modifier}+bar" = "split h";
          "${modifier}+underscore" = "split v";
          "${modifier}+a" = "focus parent";
          # TODO: Temporary workaround for https://github.com/nix-community/home-manager/issues/695
          "${modifier}+0" = null;
          "${modifier}+Shift+0" = null;
        };
      modes.resize = {
        "h" = "resize shrink width 10 px or 10 ppt";
        "j" = "resize grow height 10 px or 10 ppt";
        "k" = "resize shrink height 10 px or 10 ppt";
        "l" = "resize grow width 10 px or 10 ppt";
        "Left" = "resize shrink width 10 px or 10 ppt";
        "Down" = "resize grow height 10 px or 10 ppt";
        "Up" = "resize shrink height 10 px or 10 ppt";
        "Right" = "resize grow width 10 px or 10 ppt";
        "Escape" = "mode default";
        "Return" = "mode default";
      };
      fonts = [ "Hack Nerd Font 9" ];
      colors = {
        focused = {
          border = "#689d6a";
          childBorder = "#689d6a";
          background = "#689d6a";
          text = "#282828";
          indicator = "#282828";
        };
        focusedInactive = {
          border = "#282828";
          childBorder = "#282828";
          background = "#282828";
          text = "#928374";
          indicator = "#282828";
        };
        unfocused = {
          border = "#32302f";
          childBorder = "#32302f";
          background = "#32302f";
          text = "#928374";
          indicator = "#282828";
        };
        urgent = {
          border = "#cc241d";
          childBorder = "#cc241d";
          background = "#cc241d";
          text = "#ebdbb2";
          indicator = "#282828";
        };
      };
      bars = [
        {
          trayOutput = "primary";
          statusCommand =
            let
              config = pkgs.writeText "i3status-rust-config" ''
                theme = "gruvbox-dark"
                icons = "awesome"

                # This doesn't seem to work at the moment
                #[[block]]
                #block = "focused_window"
                #max_width = 50

                [[block]]
                block = "disk_space"
                path = "/"
                alias = "/"
                info_type = "available"
                unit = "GB"
                interval = 20
                warning = 20.0
                alert = 10.0

                [[block]]
                block = "memory"
                display_type = "memory"
                format_mem = "{Mup}%"
                format_swap = "{SUp}%"

                [[block]]
                block = "cpu"
                format = "{utilization}%"
                interval = 1

                [[block]]
                block = "load"
                interval = 1
                format = "{1m}"

                ${optionalString sysconfig.variables.hasBattery ''
                  [[block]]
                  block = "battery"
                  driver = "upower"
                  device = "DisplayDevice"
                  interval = 10
                  format = "{percentage}%"
                ''}

                ${optionalString sysconfig.variables.hasBacklightControl ''
                  [[block]]
                  block = "backlight"
                ''}

                [[block]]
                block = "sound"

                [[block]]
                block = "time"
                interval = 5
                format = "%a %-m/%-d %-H:%M"
              '';
            in
            "${pkgs.i3status-rust}/bin/i3status-rs ${config}";
          fonts = [ "Hack Nerd Font 10" ];
          colors = {
            separator = "#928374";
            background = "#282828";
            statusline = "#ebdbb2";
            focusedWorkspace = {
              border = "#689d6a";
              background = "#689d6a";
              text = "#282828";
            };
            activeWorkspace = {
              border = "#282828";
              background = "#282828";
              text = "#928374";
            };
            inactiveWorkspace = {
              border = "#32302f";
              background = "#32302f";
              text = "#928374";
            };
            urgentWorkspace = {
              border = "#cc241d";
              background = "#cc241d";
              text = "#ebdbb2";
            };
          };
        }
      ];
    };
    extraConfig = ''
      exec --no-startup-id xset dpms 600
      exec --no-startup-id ${pkgs.autorandr}/bin/autorandr --change
      ${optionalString sysconfig.networking.networkmanager.enable ''
        exec --no-startup-id ${pkgs.networkmanagerapplet}/bin/nm-applet --sm-disable
      ''}
      exec --no-startup-id ${pkgs.pasystray}/bin/pasystray --notify=none
      exec --no-startup-id ${pkgs.barrier}/bin/barrier
      exec --no-startup-id ${pkgs.syncthing-gtk}/bin/syncthing-gtk --minimized
      exec --no-startup-id ${pkgs.flameshot}/bin/flameshot

      for_window [class="mpv"] floating enable border none
      for_window [class=".*scrcpy.*"] floating enable border none
      for_window [title="Android Emulator - .*"] floating enable border none

      for_window [class="looking-glass-client"] move container to workspace 9, workspace 9, move workspace to output primary, focus, fullscreen enable
    '';
  };

  home.packages = with pkgs; [
    arandr
    nitrogen
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
        rofi.parse-known-hosts: false
      '';
    };
  };

  services = {
    kdeconnect = {
      enable = true;
      indicator = true;
    };

    picom = {
      enable = true;
      blur = true;
      shadow = true;
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

    udiskie = {
      enable = true;
      automount = false;
      tray = "always";
    };
  };
}
