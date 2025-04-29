{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules.zellij;
in {
  options.localModules.zellij = {
    enable = lib.mkEnableOption "zellij";
  };

  config = lib.mkIf cfg.enable {
    programs.zellij = {
      enable = true;
      settings = {
        pane_frames = false;
        default_layout = "compact";
        theme = "gruvbox-dark";
      };
    };
  };
}
