{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.localModules.karabiner-elements;
  json = pkgs.formats.json {};
in {
  options.localModules.karabiner-elements = {
    enable = lib.mkEnableOption "karabiner";

    additionalRules = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      description = "Additional Karabiner-Elements complex modification rules.";
    };
  };

  config = let
    rules = [
      {
        description = "Print Screen";
        manipulators = [
          {
            from.key_code = "print_screen";
            to = [
              {
                key_code = "4";
                modifiers = ["left_command" "left_shift"];
              }
            ];
            type = "basic";
          }
        ];
      }
      {
        description = "Cmd+. to Emoji Picker";
        manipulators = [
          {
            from = {
              key_code = "period";
              modifiers.mandatory = ["left_command" "left_control" "left_option"];
            };
            to = [
              {
                key_code = "spacebar";
                modifiers = ["left_command" "left_control"];
              }
            ];
            type = "basic";
          }
        ];
      }
      {
        description = "JIS underscore/pipe to Aerospace split bindings";
        manipulators = [
          {
            from = {
              key_code = "international3";
              modifiers.mandatory = ["left_command" "left_control" "left_option" "shift"];
            };
            to = [
              {
                key_code = "b";
                modifiers = ["left_command" "left_control" "left_option"];
              }
            ];
            type = "basic";
          }
          {
            from = {
              key_code = "international1";
              modifiers.mandatory = ["left_command" "left_control" "left_option" "shift"];
            };
            to = [
              {
                key_code = "v";
                modifiers = ["left_command" "left_control" "left_option"];
              }
            ];
            type = "basic";
          }
        ];
      }
      {
        description = "E/J key to switch input";
        manipulators = [
          {
            from.key_code = "grave_accent_and_tilde";
            to = [
              {
                key_code = "spacebar";
                modifiers = ["left_control"];
              }
            ];
            type = "basic";
          }
        ];
      }
      {
        description = "Cmd+D/C to Spotlight";
        manipulators = [
          {
            from = {
              key_code = "d";
              modifiers.mandatory = ["left_option" "left_command" "left_control"];
            };
            to = [
              {
                key_code = "spacebar";
                modifiers = ["left_command"];
              }
            ];
            type = "basic";
          }
          {
            from = {
              key_code = "c";
              modifiers.mandatory = ["left_option" "left_command" "left_control"];
            };
            to = [
              {
                key_code = "spacebar";
                modifiers = ["left_command"];
              }
            ];
            type = "basic";
          }
        ];
      }
      {
        description = "Ctrl to Cmd, Cmd to Aerospace";
        manipulators = [
          {
            conditions = [
              {
                bundle_identifiers = ["^org\\.alacritty$" "^com.utmapp.UTM$"];
                type = "frontmost_application_unless";
              }
            ];
            from = {
              key_code = "left_control";
              modifiers.optional = ["any"];
            };
            to = [{key_code = "left_command";}];
            type = "basic";
          }
          {
            from = {
              key_code = "left_command";
              modifiers.optional = ["any"];
            };
            to = [
              {
                key_code = "left_option";
                modifiers = ["left_command" "left_control"];
              }
            ];
            type = "basic";
          }
        ];
      }
      {
        description = "Control/Caps to Escape on tap, Control on hold";
        manipulators = [
          {
            from = {
              key_code = "left_control";
              modifiers.optional = ["any"];
            };
            to = [{key_code = "left_control";}];
            to_if_alone = [{key_code = "escape";}];
            type = "basic";
          }
          {
            from = {
              key_code = "caps_lock";
              modifiers.optional = ["any"];
            };
            to = [{key_code = "left_control";}];
            to_if_alone = [{key_code = "escape";}];
            type = "basic";
          }
        ];
      }
      {
        description = "Toggle caps_lock by pressing left_shift + right_shift at the same time";
        manipulators = [
          {
            from = {
              key_code = "left_shift";
              modifiers = {
                mandatory = ["right_shift"];
                optional = ["caps_lock"];
              };
            };
            to = [{key_code = "caps_lock";}];
            type = "basic";
          }
          {
            from = {
              key_code = "right_shift";
              modifiers = {
                mandatory = ["left_shift"];
                optional = ["caps_lock"];
              };
            };
            to = [{key_code = "caps_lock";}];
            type = "basic";
          }
        ];
      }
      {
        description = "Change ¥ to Alt+¥";
        manipulators = [
          {
            from.key_code = "international3";
            to = [
              {
                key_code = "international3";
                modifiers = ["option"];
              }
            ];
            type = "basic";
          }
        ];
      }
      {
        description = "Change Alt+¥ to ¥";
        manipulators = [
          {
            from = {
              key_code = "international3";
              modifiers.mandatory = ["option"];
            };
            to = [{key_code = "international3";}];
            type = "basic";
          }
        ];
      }
    ];
  in
    lib.mkIf cfg.enable {
      home.file.".config/karabiner/assets/complex_modifications/nix.json".source = json.generate "karabiner-nix-rules.json" {
        title = "Nix Managed Rules";
        rules = rules ++ cfg.additionalRules;
      };
    };
}
