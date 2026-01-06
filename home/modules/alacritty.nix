{
  config,
  lib,
  ...
}: let
  cfg = config.localModules.alacritty;
in {
  options.localModules.alacritty = {
    enable = lib.mkEnableOption "alacritty";
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      TERMINAL = "alacritty";
    };

    programs.alacritty = {
      enable = true;
      settings = {
        env = {
          WINIT_X11_SCALE_FACTOR = "1";
          TERM = "xterm-256color";
        };
        font = {
          size = 12.0;
          normal = {
            family = "Hack Nerd Font";
          };
        };
        window = {
          opacity = 0.95;
        };
        colors = {
          primary = {
            background = "#282828";
            foreground = "#ebdbb2";
          };
          normal = {
            black = "#282828";
            red = "#cc241d";
            green = "#98971a";
            yellow = "#d79921";
            blue = "#458588";
            magenta = "#b16286";
            cyan = "#689d6a";
            white = "#a89984";
          };
          bright = {
            black = "#928374";
            red = "#fb4934";
            green = "#b8bb26";
            yellow = "#fabd2f";
            blue = "#83a598";
            magenta = "#d3869b";
            cyan = "#8ec07c";
            white = "#ebdbb2";
          };
        };
        keyboard.bindings = [
          {
            key = "C";
            mods = "Control|Shift";
            action = "Copy";
          }
          {
            key = "V";
            mods = "Control|Shift";
            action = "Paste";
          }
          {
            key = "F";
            mods = "Control|Shift";
            action = "SearchForward";
          }
          {
            key = "B";
            mods = "Control|Shift";
            action = "SearchBackward";
          }

          # Unbind all Command bindings
          {
            key = "0";
            mods = "Command";
            action = "None";
          }
          {
            key = "1";
            mods = "Command";
            action = "None";
          }
          {
            key = "2";
            mods = "Command";
            action = "None";
          }
          {
            key = "3";
            mods = "Command";
            action = "None";
          }
          {
            key = "4";
            mods = "Command";
            action = "None";
          }
          {
            key = "5";
            mods = "Command";
            action = "None";
          }
          {
            key = "6";
            mods = "Command";
            action = "None";
          }
          {
            key = "7";
            mods = "Command";
            action = "None";
          }
          {
            key = "8";
            mods = "Command";
            action = "None";
          }
          {
            key = "9";
            mods = "Command";
            action = "None";
          }
          {
            key = "+";
            mods = "Command";
            action = "None";
          }
          {
            key = "-";
            mods = "Command";
            action = "None";
          }
          {
            key = "=";
            mods = "Command";
            action = "None";
          }
          {
            key = "[";
            mods = "Command|Shift";
            action = "None";
          }
          {
            key = "]";
            mods = "Command|Shift";
            action = "None";
          }
          {
            key = "B";
            mods = "Command";
            action = "None";
          }
          {
            key = "C";
            mods = "Command";
            action = "None";
          }
          {
            key = "F";
            mods = "Command";
            action = "None";
          }
          {
            key = "F";
            mods = "Command|Control";
            action = "None";
          }
          {
            key = "H";
            mods = "Command";
            action = "None";
          }
          {
            key = "H";
            mods = "Command|Alt";
            action = "None";
          }
          {
            key = "K";
            mods = "Command";
            action = "None";
          }
          {
            key = "M";
            mods = "Command";
            action = "None";
          }
          {
            key = "N";
            mods = "Command";
            action = "None";
          }
          {
            key = "NumpadAdd";
            mods = "Command";
            action = "None";
          }
          {
            key = "NumpadSubtract";
            mods = "Command";
            action = "None";
          }
          {
            key = "Q";
            mods = "Command";
            action = "None";
          }
          {
            key = "T";
            mods = "Command";
            action = "None";
          }
          {
            key = "Tab";
            mods = "Command";
            action = "None";
          }
          {
            key = "Tab";
            mods = "Command|Shift";
            action = "None";
          }
          {
            key = "V";
            mods = "Command";
            action = "None";
          }
          {
            key = "W";
            mods = "Command";
            action = "None";
          }
        ];
      };
    };
  };
}
