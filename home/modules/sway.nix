{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules.sway;
  rofiPkg = pkgs.rofi-wayland.override {
    plugins = [
      # Workaround for https://github.com/NixOS/nixpkgs/issues/298539
      (pkgs.rofi-calc.override {
        rofi-unwrapped = pkgs.rofi-wayland-unwrapped;
      })
    ];
  };
  rofimojiPkg = pkgs.rofimoji.override {
    rofi = rofiPkg;
  };
in {
  options.localModules.sway = {
    enable = lib.mkEnableOption "sway";

    useNetworkManager = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = ''
        Enable packages which rely on NetworkManager.
      '';
    };

    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        The wallpaper image to use by default.
      '';
    };

    primaryOutput = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "eDP-1";
      description = ''
        The display output to use as primary.
      '';
    };

    output = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
      default = {};
      example = {"HDMI-A-2" = {bg = "~/path/to/background.png fill";};};
      description = ''
        An attribute set that defines output modules. See
        {manpage}`sway-output(5)`
        for options.
      '';
    };

    workspaceOutputAssign = lib.mkOption {
      type = let
        workspaceOutputOpts = lib.types.submodule {
          options = {
            workspace = lib.mkOption {
              type = lib.types.str;
              default = "";
              example = "Web";
              description = ''
                Name of the workspace to assign.
              '';
            };

            output = lib.mkOption {
              type = lib.types.either lib.types.str (lib.types.listOf lib.types.str);
              default = "";
              example = "eDP";
              description = ''
                Name of the output.
              '';
            };
          };
        };
      in
        lib.types.listOf workspaceOutputOpts;
      default = [];
      description = "Assign workspaces to outputs.";
    };
  };

  config = lib.mkIf cfg.enable {
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
      checkConfig = false; # Workaround for https://github.com/nix-community/home-manager/issues/5311
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
        terminal = "foot";
        focus = {
          followMouse = false;
          mouseWarping = false;
        };
        keybindings = let
          modifier = config.wayland.windowManager.sway.config.modifier;
          screenshot = pkgs.writeScriptBin "screenshot" ''
            ${lib.getExe pkgs.grim} -g "$(${lib.getExe pkgs.slurp})" - |
              ${lib.getExe pkgs.satty} -f - \
                --early-exit \
                --copy-command ${lib.getExe' pkgs.wl-clipboard "wl-copy"}
          '';
        in
          lib.mkOptionDefault {
            "${modifier}+d" = "exec ${lib.getExe rofiPkg} -show combi";
            "${modifier}+c" = "exec ${lib.getExe rofiPkg} -show calc -modi calc -no-show-match -no-sort";
            "${modifier}+period" = "exec ${lib.getExe' rofimojiPkg "rofimoji"}";
            "${modifier}+n" = "exec ${lib.getExe' pkgs.swaynotificationcenter "swaync-client"} -t -sw";
            "${modifier}+End" = "exec ${lib.getExe config.programs.swaylock.package}";
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
            "--whole-window ${modifier}+button4" = "workspace prev";
            "--whole-window ${modifier}+button5" = "workspace next";
            "Print" = "exec ${lib.getExe screenshot}";
            "Control+Mod1+Prior" = "exec ${lib.getExe' pkgs.avizo "volumectl"} -u up";
            "XF86AudioRaiseVolume" = "exec ${lib.getExe' pkgs.avizo "volumectl"} -u up";
            "Control+Mod1+Next" = "exec ${lib.getExe' pkgs.avizo "volumectl"} -u down";
            "XF86AudioLowerVolume" = "exec ${lib.getExe' pkgs.avizo "volumectl"} -u down";
            "XF86AudioMute" = "exec ${lib.getExe' pkgs.avizo "volumectl"} toggle-mute";
            "XF86AudioMicMute" = "exec ${lib.getExe' pkgs.avizo "volumectl"} -m toggle-mute";
            "XF86MonBrightnessUp" = "exec ${lib.getExe' pkgs.avizo "lightctl"} up";
            "XF86MonBrightnessDown" = "exec ${lib.getExe' pkgs.avizo "lightctl"} down";
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
        bars = [];
        assigns = {
          "2" = [
            {class = "^discord$";}
            {class = "^Element$";}
            {class = "^SchildiChat$";}
            {class = "^Skype$";}
            {class = "^Slack$";}
            {app_id = "^thunderbird$";}
            {
              title = "^LINE$";
              class = "^steam_proton$";
            }
          ];
          "3" = [
            {class = "^Logseq$";}
          ];
          "7" = [
            {class = "^jetbrains-studio$";}
          ];
        };
        floating = {
          border = 1;
          titlebar = false;
          criteria = [
            {app_id = "mpv";}
            {app_id = "com.gabm.satty";}
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
        output =
          {
            "*" = lib.mkIf (cfg.wallpaper != null) {
              bg = "${cfg.wallpaper} fill";
            };
          }
          // cfg.output;
        inherit (cfg) workspaceOutputAssign;
      };
    };

    home.packages = with pkgs; [
      adwaita-icon-theme
      i3-swallow
      pavucontrol
      wayvnc
      wdisplays
    ];

    programs = {
      rofi = {
        enable = true;
        package = rofiPkg;
        theme = "gruvbox-dark";
        extraConfig = {
          modi = "window,drun,run,ssh,combi";
          combi-modi = "window,drun,ssh";
          show-icons = true;
          parse-known-hosts = false;
        };
      };

      swaylock = {
        enable = true;
        settings = {
          image = lib.mkIf (cfg.wallpaper != null) cfg.wallpaper;
          indicator-idle-visible = true;
        };
      };

      waybar = {
        enable = true;
        systemd.enable = true;
        settings = {
          mainBar = {
            layer = "top";
            position = "top";
            height = 24;
            output = lib.mkIf (cfg.primaryOutput != null) [cfg.primaryOutput];
            modules-left = ["sway/workspaces" "sway/mode"];
            modules-center = ["sway/window"];
            modules-right = [
              "tray"
              #"disk"
              #"memory"
              #"cpu"
              #"backlight"
              #"wireplumber"
              "battery"
              "idle_inhibitor"
              "clock"
            ];
            battery = {
              interval = 5;
              format = "{icon}  {capacity}%";
              format-charging = "  {capacity}%";
              format-plugged = "  {capacity}%";
              format-alt = "{icon}  {time}";
              format-icons = ["" "" "" "" ""];
            };
            clock = {
              interval = 5;
              format = "{:%Y-%m-%d %H:%M %Z}";
              tooltip-format = "<tt>{calendar}</tt>";
              timezones = [
                ""
                "Asia/Tokyo"
              ];
              calendar = {
                mode = "year";
                mode-mon-col = 3;
                on-click-right = "mode";
                format = {
                  months = "<span color='#ffead3'><b>{}</b></span>";
                  days = "<span color='#ecc6d9'><b>{}</b></span>";
                  weekdays = "<span color='#ffcc66'><b>{}</b></span>";
                  today = "<span color='#ff6699'><b><u>{}</u></b></span>";
                };
              };
              actions = {
                on-click = "tz_up";
                on-click-right = "mode";
                on-click-forward = "tz_up";
                on-click-backward = "tz_down";
                on-scroll-up = "shift_up";
                on-scroll-down = "shift_down";
              };
            };
            "sway/window" = {
              all-outputs = true;
            };
            "sway/workspaces" = {
              all-outputs = true;
              enable-bar-scroll = true;
              disable-scroll-wraparound = true;
            };
            idle_inhibitor = {
              format = "{icon}";
              format-icons = {
                "activated" = "";
                "deactivated" = "";
              };
            };
          };
        };
      };
    };

    localModules = {
      inhibit-bridge.enable = true;

      trayscale.enable = true;
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

      kdeconnect = {
        enable = true;
        indicator = true;
      };

      network-manager-applet.enable = cfg.useNetworkManager;

      pasystray = {
        enable = true;
        extraOptions = ["--notify=none"];
      };

      swayidle = {
        enable = true;
        timeouts = [
          {
            timeout = 300;
            command = "${lib.getExe' pkgs.sway "swaymsg"} 'output * dpms off'";
            resumeCommand = "${lib.getExe' pkgs.sway "swaymsg"} 'output * dpms on'";
          }
        ];
      };

      swaync = {
        enable = true;
        settings = {
          widgets = [
            "inhibitors"
            "title"
            "dnd"
            "mpris"
            "notifications"
          ];
        };
      };

      udiskie = {
        enable = true;
        automount = false;
        tray = "always";
      };
    };
  };
}
