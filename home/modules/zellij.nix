{
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
    # TODO: Use simple zjstatus layout
    # https://github.com/dj95/zjstatus
    programs.zellij = {
      enable = true;
      settings = {
        show_startup_tips = false;
        show_release_notes = false;

        pane_frames = false;
        default_layout = "compact";
        theme = "gruvbox-dark";
        simplified_ui = true;

        keybinds.normal = {
          _props.clear-defaults = true;
          bind = {
            _args = ["Ctrl a"];
            SwitchToMode = "Tmux";
          };
          unbind = "Ctrl b";
        };
      };
    };
  };
}
