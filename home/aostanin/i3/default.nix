{
  pkgs,
  config,
  lib,
  nixosConfig,
  ...
}:
with lib; let
  rofiWithPlugins = with pkgs;
    rofi.override {
      plugins = [
        rofi-calc
      ];
    };
in {
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
    ];
  };

  xsession.windowManager.i3 = {
    enable = true;
    config = {
      modifier = "Mod4";
      terminal = "alacritty";
      focus.followMouse = false;
      keybindings = let
        modifier = config.xsession.windowManager.i3.config.modifier;
      in
        mkOptionDefault {
          "Print" = "exec ${pkgs.flameshot}/bin/flameshot gui";
          "${modifier}+d" = "exec ${pkgs.rofi}/bin/rofi -show combi";
          "${modifier}+c" = "exec ${rofiWithPlugins}/bin/rofi -show calc -modi calc -no-show-match -no-sort";
          "${modifier}+period" = "exec ${pkgs.rofimoji}/bin/rofimoji";
          "${modifier}+Shift+s" = "sticky toggle";
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
          "${modifier}+x" = "[urgent=latest] focus";
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
      fonts = {
        names = ["Hack Nerd Font"];
        size = 9.0;
      };
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
          statusCommand = let
            config = pkgs.writeText "i3status-rust-config" ''
              [theme]
              theme = "gruvbox-dark"

              [icons]
              icons = "awesome6"

              [[block]]
              block = "disk_space"
              alert_unit = "GB"

              [[block]]
              block = "memory"
              format = " $icon $mem_total_used_percents.eng(w:2) "

              [[block]]
              block = "cpu"

              [[block]]
              block = "load"

              ${optionalString nixosConfig.variables.hasBattery ''
                [[block]]
                block = "battery"
                driver = "upower"
                device = "DisplayDevice"
              ''}

              ${optionalString nixosConfig.variables.hasBacklightControl ''
                [[block]]
                block = "backlight"
              ''}

              [[block]]
              block = "sound"


              ${optionalString (nixosConfig.time.timeZone != "Asia/Tokyo") ''
                [[block]]
                block = "time"
                timezone = "Asia/Tokyo"
                format = " $icon JP $timestamp.datetime(f:'%-H:%M')"
              ''}

              [[block]]
              block = "time"
              format = " $icon $timestamp.datetime(f:'%a %-m/%-d %-H:%M') "
            '';
          in "${pkgs.i3status-rust}/bin/i3status-rs ${config}";
          fonts = {
            names = ["Hack Nerd Font" "Font Awesome 6 Free"];
            size = 10.0;
          };
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
      startup =
        [
          {
            command = "${pkgs.autorandr}/bin/autorandr --change";
            notification = false;
          }
          {
            command = "${pkgs.pasystray}/bin/pasystray --notify=none";
            notification = false;
          }
          {
            command = "${pkgs.barrier}/bin/barrier";
            notification = false;
          }
        ]
        ++ optionals nixosConfig.networking.networkmanager.enable [
          {
            command = "${pkgs.networkmanagerapplet}/bin/nm-applet --sm-disable";
            notification = false;
          }
        ];
      assigns = {
        "2" = [
          {class = "^discord$";}
          {class = "^SchildiChat$";}
          {class = "^Skype$";}
          {class = "^Slack$";}
          {class = "^thunderbird$";}
        ];
      };
      floating = {
        border = 1;
        titlebar = false;
        criteria = [
          {class = "mpv";}
          {class = ".*scrcpy.*";}
          {class = "Android Emulator - .*";}
          {class = "Picture-in-Picture";}
        ];
      };
      window = {
        border = 1;
        titlebar = false;
        hideEdgeBorders = "smart";
        commands = [
          {
            criteria = {class = "looking-glass-client";};
            command = "border none, move container to workspace 9, workspace 9, move workspace to output primary, focus, fullscreen enable";
          }
          {
            criteria = {class = "mpv";};
            command = "border none";
          }
          {
            criteria = {class = ".*scrcpy.*";};
            command = "border none";
          }
          {
            criteria = {class = "Android Emulator - .*";};
            command = "border none";
          }
          {
            criteria = {class = "Picture-in-Picture";};
            command = "border none";
          }
        ];
      };
    };
  };

  home.packages = with pkgs; [
    arandr
    i3-swallow
    nitrogen
    pavucontrol
  ];

  programs = {
    rofi = {
      enable = true;
      theme = "gruvbox-dark";
      extraConfig = {
        modi = "window,drun,run,ssh,combi";
        combi-modi = "window,drun,ssh";
        show-icons = true;
        parse-known-hosts = false;
      };
    };
  };

  services = {
    flameshot.enable = true;

    kdeconnect = {
      enable = true;
      indicator = true;
    };

    picom = {
      enable = true;
      shadow = true;
      settings = {
        backend = "glx";
        blur-background = true;
        blur-background-exclude = [
          "class_g ?= 'Peek'"
        ];
        blur = {
          method = "dual_kawase";
          strength = 2;
        };
      };
    };

    udiskie = {
      enable = true;
      automount = false;
      tray = "always";
    };

    xidlehook = {
      enable = true;
      not-when-audio = true;
      timers = [
        {
          delay = 300;
          command = "${pkgs.xorg.xset}/bin/xset dpms force off";
          canceller = "${pkgs.xorg.xset}/bin/xset dpms force on";
        }
      ];
    };
  };
}
