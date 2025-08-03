{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules.tmux;
in {
  options.localModules.tmux = {
    enable = lib.mkEnableOption "tmux";
  };

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      aggressiveResize = true;
      baseIndex = 1;
      clock24 = true;
      escapeTime = 0;
      extraConfig = ''
        set -g allow-passthrough on
      '';
      keyMode = "vi";
      mouse = true;
      plugins = with pkgs.tmuxPlugins; [
        pain-control
      ];
      shortcut = "a";
      terminal = "screen-256color";
      tmuxp.enable = true;
    };
  };
}
