{
  config,
  inputs,
  lib,
  ...
}: let
  cfg = config.localModules.paneru;

  # cmd is mapped to cmd-ctrl-alt through Karabiner-Elements
  mod = "cmd + ctrl + alt";

  directional = prefix: command:
    lib.concatMapAttrs (dir: keys:
      lib.genAttrs (map (key: "${prefix} - ${key}") keys) (_: "${command} ${dir}")) {
      west = ["h" "leftarrow"];
      south = ["j" "downarrow"];
      north = ["k" "uparrow"];
      east = ["l" "rightarrow"];
    };

  workspaces = lib.concatMapAttrs (_: n: {
    "${mod} - ${n}" = "window virtualnum ${n}";
    "${mod} + shift - ${n}" = "window virtualsendnum ${n}";
  }) (lib.genAttrs (map toString (lib.range 1 9)) lib.id);

  bindings =
    directional mod "window focus"
    // directional "${mod} + shift" "window swap"
    // workspaces
    // {
      "${mod} - home" = "window focus first";
      "${mod} - end" = "window focus last";
      "${mod} + shift - home" = "window swap first";
      "${mod} + shift - end" = "window swap last";

      "${mod} - u" = "window virtual south";
      "${mod} - i" = "window virtual north";
      "${mod} + shift - u" = "window virtualmove south";
      "${mod} + shift - i" = "window virtualmove north";

      "${mod} - r" = "window resize";
      "${mod} + shift - r" = "window shrink";
      "${mod} - f" = "window fullwidth";
      "${mod} + shift - c" = "window center";
      "${mod} + shift - space" = "window manage";
      "${mod} - w" = "window tabbeddisplay";
      # Key names are US ANSI positions; these are the JIS [ and ] keys
      "${mod} - rightbracket" = "window stack";
      "${mod} - backslash" = "window unstack";
      "${mod} - v" = "window stack";
      "${mod} - b" = "window unstack";
    };
in {
  imports = [inputs.paneru.darwinModules.paneru];

  options.localModules.paneru = {
    enable = lib.mkEnableOption "paneru";
  };

  config = lib.mkIf cfg.enable {
    services.paneru = {
      enable = true;
      config = ''
        paneru.setup ${lib.generators.toLua {} {
          options = {
            focus_follows_mouse = false;
            mouse_follows_focus = false;
            preset_column_widths = [0.33333 0.5 0.66667];
            preset_stack_heights = [0.33333 0.5 0.66667];
          };
          # Pins the strip to the left edge when it fits, like niri
          swipe.continuous = false;
          decorations.active.border = {
            enabled = true;
            color = "#689d6a";
            width = 3.0;
            radius = 16.0;
          };
          padding = {
            top = 3;
            bottom = 3;
            left = 3;
            right = 3;
          };
          windows.all = {
            title = ".*";
            width = 0.5;
            horizontal_padding = 3;
            vertical_padding = 3;
          };
        }}

        ${lib.concatLines (lib.mapAttrsToList (chord: command: "paneru.bind(${builtins.toJSON chord}, ${builtins.toJSON command})") bindings)}
        paneru.bind("${mod} - return", function() os.execute("open -na Alacritty") end)
      '';
    };

    # Paneru keeps a separate window strip per display
    system.defaults.spaces.spans-displays = false;
  };
}
