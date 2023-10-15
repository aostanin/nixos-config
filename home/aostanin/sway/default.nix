{
  pkgs,
  config,
  lib,
  nixosConfig,
  ...
}: {
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
          "Control+Mod1+Prior" = "exec $${pkgs.avizo}/bin/volumectl -u up";
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
    extraConfig = ''
      output * bg ${config.home.homeDirectory}/Sync/wallpaper/t440p.png fill
    '';
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
          output = [
            "eDP-1"
          ];
          modules-left = ["sway/workspaces" "sway/mode"];
          modules-center = [];
          # TODO: disk, memory, cpu, load, battery, backlight, sound, timezones
          modules-right = ["tray" "clock"];
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

    network-manager-applet.enable = nixosConfig.networking.networkmanager.enable;

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
}
