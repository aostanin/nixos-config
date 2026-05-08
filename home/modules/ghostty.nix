{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.localModules.ghostty;
in {
  options.localModules.ghostty = {
    enable = lib.mkEnableOption "ghostty";
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      TERMINAL = "ghostty";
    };

    programs.ghostty = {
      enable = true;
      package =
        if pkgs.stdenv.isDarwin
        then pkgs.ghostty-bin
        else pkgs.ghostty;
      clearDefaultKeybinds = true;
      settings = {
        term = "xterm-256color";

        quit-after-last-window-closed = true;

        font-family = "Hack Nerd Font";
        font-size = 12;

        background-opacity = 0.95;
        background = "282828";
        foreground = "ebdbb2";
        palette = [
          "0=#282828"
          "1=#cc241d"
          "2=#98971a"
          "3=#d79921"
          "4=#458588"
          "5=#b16286"
          "6=#689d6a"
          "7=#a89984"
          "8=#928374"
          "9=#fb4934"
          "10=#b8bb26"
          "11=#fabd2f"
          "12=#83a598"
          "13=#d3869b"
          "14=#8ec07c"
          "15=#ebdbb2"
        ];

        keybind = [
          "ctrl+shift+c=copy_to_clipboard"
          "ctrl+shift+v=paste_from_clipboard"
          "super+c=copy_to_clipboard"
          "super+v=paste_from_clipboard"
        ];
      };
    };
  };
}
