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
          inner.horizontal = 1;
          inner.vertical = 1;
          outer.left = 0;
          outer.right = 0;
          outer.top = 0;
          outer.bottom = 0;
        };

        mode.main.binding = let
          modifier = "alt";
        in {
          # Focus
          "${modifier}-h" = "focus left";
          "${modifier}-j" = "focus down";
          "${modifier}-k" = "focus up";
          "${modifier}-l" = "focus right";

          # Move
          "${modifier}-shift-h" = "move left";
          "${modifier}-shift-j" = "move down";
          "${modifier}-shift-k" = "move up";
          "${modifier}-shift-l" = "move right";

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
          "${modifier}-s" = "layout accordion horizontal vertical";

          # Join
          "${modifier}-v" = "join-with right";
          "${modifier}-b" = "join-with down";

          # Terminal
          "${modifier}-enter" = "exec-and-forget open -na Alacritty";

          # Resize mode
          "${modifier}-r" = "mode resize";
        };

        mode.resize.binding = {
          h = "resize width -50";
          j = "resize height +50";
          k = "resize height -50";
          l = "resize width +50";
          esc = "mode main";
          enter = "mode main";
        };
      };
    };
  };
}
