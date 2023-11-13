{
  pkgs,
  config,
  lib,
  osConfig,
  ...
}: let
  # TODO: Need unstable for now https://github.com/NixOS/nixpkgs/pull/251800
  swayncPkg = pkgs.unstable.swaynotificationcenter;
in {
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
    ];
  };

  xsession = {
    enable = true;
    preferStatusNotifierItems = true;
  };

  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures = {
      base = true;
      gtk = true;
    };
    extraSessionCommands = ''
      # Workaround for https://github.com/nix-community/home-manager/issues/2659
      . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
    '';
    config = {
      modifier = "Mod4";
      terminal = "alacritty";
      focus.followMouse = false;
      keybindings = let
        modifier = config.wayland.windowManager.sway.config.modifier;
        rofiWithPlugins = with pkgs;
          rofi.override {
            plugins = [
              rofi-calc
            ];
          };
      in
        lib.mkOptionDefault {
          "${modifier}+d" = "exec ${pkgs.rofi}/bin/rofi -show combi";
          "${modifier}+c" = "exec ${rofiWithPlugins}/bin/rofi -show calc -modi calc -no-show-match -no-sort";
          "${modifier}+period" = "exec ${pkgs.rofimoji}/bin/rofimoji";
          "${modifier}+n" = "exec ${swayncPkg}/bin/swaync-client -t -sw";
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
          "Print" = "exec ${pkgs.flameshot}/bin/flameshot gui";
          "Control+Mod1+Prior" = "exec ${pkgs.avizo}/bin/volumectl -u up";
          "XF86AudioRaiseVolume" = "exec ${pkgs.avizo}/bin/volumectl -u up";
          "Control+Mod1+Next" = "exec ${pkgs.avizo}/bin/volumectl -u down";
          "XF86AudioLowerVolume" = "exec ${pkgs.avizo}/bin/volumectl -u down";
          "XF86AudioMute" = "exec ${pkgs.avizo}/bin/volumectl toggle-mute";
          "XF86AudioMicMute" = "exec ${pkgs.avizo}/bin/volumectl -m toggle-mute";
          "XF86MonBrightnessUp" = "exec ${pkgs.avizo}/bin/lightctl up";
          "XF86MonBrightnessDown" = "exec ${pkgs.avizo}/bin/lightctl down";
          # Workaround for https://github.com/nix-community/home-manager/issues/695
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
      seat."*" = {
        hide_cursor = "when-typing enable";
      };
      input = {
        "type:keyboard" = {
          xkb_layout = "jp";
          xkb_options = "ctrl:nocaps,shift:both_capslock";
        };
        "type:touchpad" = {
          click_method = "clickfinger";
          natural_scroll = "enabled";
          tap = "disabled";
        };
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
        {command = "waybar";}
      ];
      startup = [
        # TODO: Switch to kanshi
        # {command = "${pkgs.autorandr}/bin/autorandr --change";}
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
          {app_id = "mpv";}
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
            criteria = {app_id = "looking-glass-client";};
            command = "border none, move container to workspace 9, workspace 9, focus, fullscreen enable";
          }
          {
            criteria = {app_id = "mpv";};
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
          {
            criteria = {app_id = "flameshot";};
            command = "fullscreen enable global";
          }
        ];
      };
      output = osConfig.localModules.desktop.output;
      workspaceOutputAssign = osConfig.localModules.desktop.workspaceOutputAssign;
    };
  };

  home.packages = with pkgs; [
    arandr
    i3-swallow
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

    waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "left";
          width = 32;
          output = [osConfig.localModules.desktop.primaryOutput];
          modules-left = ["sway/workspaces" "sway/mode"];
          modules-center = [];
          modules-right = [
            "tray"
            #"disk"
            #"memory"
            #"cpu"
            #"backlight"
            #"wireplumber"
            "battery"
            "clock"
          ];
          "clock" = {
            interval = 5;
            format = "{:%H\n%M}";
          };
          "sway/workspaces" = {
            all-outputs = true;
          };
        };
      };
    };
  };

  services = {
    avizo = {
      enable = true;
      settings.default = {
        time = 1.0;
        y-offset = 0.5;
        fade-in = 0.1;
        fade-out = 0.2;
        padding = 10;
      };
    };

    clipman.enable = true;

    flameshot.enable = true;

    kdeconnect = {
      enable = true;
      indicator = true;
    };

    network-manager-applet.enable = osConfig.networking.networkmanager.enable;

    pasystray = {
      enable = true;
      extraOptions = ["--notify=none"];
    };

    swayidle = {
      enable = true;
      timeouts = [
        {
          timeout = 300;
          command = "${pkgs.sway}/bin/swaymsg 'output * dpms off'";
          resumeCommand = "${pkgs.sway}/bin/swaymsg 'output * dpms on'";
        }
      ];
    };

    udiskie = {
      enable = true;
      automount = false;
      tray = "always";
    };
  };

  systemd.user = {
    # TODO: Switch to home-manager module https://github.com/nix-community/home-manager/pull/4249
    services.swaync = {
      Unit = {
        Description = "Swaync notification daemon";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };

      Service = {
        Type = "simple";
        ExecStart = "${swayncPkg}/bin/swaync";
        Restart = "always";
      };

      Install = {WantedBy = ["graphical-session.target"];};
    };
  };

  xdg.configFile."swaync/config.json".source = pkgs.writeText "swaync/config.json" ''
    {
      "$schema": "/etc/xdg/swaync/configSchema.json",
      "positionX": "right",
      "positionY": "top",
      "layer": "overlay",
      "control-center-layer": "top",
      "layer-shell": true,
      "cssPriority": "application",
      "control-center-margin-top": 0,
      "control-center-margin-bottom": 0,
      "control-center-margin-right": 0,
      "control-center-margin-left": 0,
      "notification-2fa-action": true,
      "notification-inline-replies": false,
      "notification-icon-size": 64,
      "notification-body-image-height": 100,
      "notification-body-image-width": 200,
      "timeout": 10,
      "timeout-low": 5,
      "timeout-critical": 0,
      "fit-to-screen": true,
      "control-center-width": 500,
      "control-center-height": 600,
      "notification-window-width": 500,
      "keyboard-shortcuts": true,
      "image-visibility": "when-available",
      "transition-time": 200,
      "hide-on-clear": false,
      "hide-on-action": true,
      "script-fail-notify": true,
      "scripts": {
      },
      "notification-visibility": {
      },
      "widgets": [
        "inhibitors",
        "title",
        "dnd",
        "mpris",
        "notifications"
      ],
      "widget-config": {
        "inhibitors": {
          "text": "Inhibitors",
          "button-text": "Clear All",
          "clear-all-button": true
        },
        "title": {
          "text": "Notifications",
          "clear-all-button": true,
          "button-text": "Clear All"
        },
        "dnd": {
          "text": "Do Not Disturb"
        },
        "label": {
          "max-lines": 5,
          "text": "Label Text"
        },
        "mpris": {
          "image-size": 96,
          "image-radius": 12
        }
      }
    }
  '';
}
