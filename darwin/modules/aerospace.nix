{
  config,
  lib,
  ...
}: let
  cfg = config.localModules.aerospace;
in {
  options.localModules.aerospace = {
    enable = lib.mkEnableOption "aerospace";
  };

  config = lib.mkIf cfg.enable {
    services.aerospace = {
      enable = true;
      settings = {
        gaps = {
          inner.horizontal = 3;
          inner.vertical = 3;
          outer.left = 3;
          outer.right = 3;
          outer.top = 3;
          outer.bottom = 3;
        };

        enable-normalization-flatten-containers = false;
        enable-normalization-opposite-orientation-for-nested-containers = false;

        workspace-to-monitor-force-assignment = {
          "1" = ["lg" "built-in"];
          "2" = ["dell" "built-in"];
          "3" = ["built-in"];
          "4" = ["lg" "built-in"];
          "5" = ["dell" "built-in"];
          "6" = ["built-in"];
          "7" = ["lg" "built-in"];
          "8" = ["lg" "built-in"];
          "9" = ["lg" "built-in"];
        };

        mode.main.binding = let
          # cmd is mapped to cmd-ctrl-alt through Karabiner-
          modifier = "cmd-ctrl-alt";
        in {
          # Focus
          "${modifier}-h" = "focus left";
          "${modifier}-j" = "focus down";
          "${modifier}-k" = "focus up";
          "${modifier}-l" = "focus right";
          "${modifier}-left" = "focus left";
          "${modifier}-down" = "focus down";
          "${modifier}-up" = "focus up";
          "${modifier}-right" = "focus right";

          # Move
          "${modifier}-shift-h" = "move left";
          "${modifier}-shift-j" = "move down";
          "${modifier}-shift-k" = "move up";
          "${modifier}-shift-l" = "move right";
          "${modifier}-shift-left" = "move left";
          "${modifier}-shift-down" = "move down";
          "${modifier}-shift-up" = "move up";
          "${modifier}-shift-right" = "move right";

          # Workspaces
          "${modifier}-1" = "workspace 1";
          "${modifier}-2" = "workspace 2";
          "${modifier}-3" = "workspace 3";
          "${modifier}-4" = "workspace 4";
          "${modifier}-5" = "workspace 5";
          "${modifier}-6" = "workspace 6";
          "${modifier}-7" = "workspace 7";
          "${modifier}-8" = "workspace 8";
          "${modifier}-9" = "workspace 9";

          # Move to workspace
          "${modifier}-shift-1" = "move-node-to-workspace 1";
          "${modifier}-shift-2" = "move-node-to-workspace 2";
          "${modifier}-shift-3" = "move-node-to-workspace 3";
          "${modifier}-shift-4" = "move-node-to-workspace 4";
          "${modifier}-shift-5" = "move-node-to-workspace 5";
          "${modifier}-shift-6" = "move-node-to-workspace 6";
          "${modifier}-shift-7" = "move-node-to-workspace 7";
          "${modifier}-shift-8" = "move-node-to-workspace 8";
          "${modifier}-shift-9" = "move-node-to-workspace 9";

          # Layout
          "${modifier}-f" = "fullscreen";
          "${modifier}-shift-space" = "layout floating tiling";
          "${modifier}-e" = "layout tiles horizontal vertical";
          "${modifier}-s" = "layout accordion vertical";
          "${modifier}-w" = "layout accordion horizontal";

          # Split
          "${modifier}-b" = "split horizontal";
          "${modifier}-v" = "split vertical";

          # Terminal
          "${modifier}-enter" = "exec-and-forget open -na Alacritty";

          # Resize mode
          "${modifier}-r" = "mode resize";

          # Actions
          "${modifier}-shift-q" = "close";
        };

        mode.resize.binding = {
          h = "resize width -50";
          j = "resize height +50";
          k = "resize height -50";
          l = "resize width +50";
          left = "resize width -50";
          down = "resize height +50";
          up = "resize height -50";
          right = "resize width +50";
          esc = "mode main";
          enter = "mode main";
        };
      };
    };

    services.jankyborders = {
      enable = true;
      width = 3.0;
      hidpi = true;
      active_color = "0xff689d6a";
      inactive_color = "";
      order = "above";
    };
  };
}
