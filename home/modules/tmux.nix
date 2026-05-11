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
    programs.tmux = rec {
      enable = true;
      aggressiveResize = true;
      baseIndex = 1;
      clock24 = true;
      escapeTime = 0;
      focusEvents = true;
      extraConfig = ''
        set -g allow-passthrough on
        set -s extended-keys on
        set -as terminal-features 'xterm*:extkeys'
        bind-key C-${shortcut} last-window

        set -g @thumbs-command 'printf %s {} | ${
          if pkgs.stdenv.isDarwin
          then "pbcopy"
          else "wl-copy"
        }'
        set -g @thumbs-upcase-command '${
          if pkgs.stdenv.isDarwin
          then "open"
          else "xdg-open"
        } {}'
      '';
      keyMode = "vi";
      mouse = true;
      plugins = with pkgs.tmuxPlugins; [
        pain-control
        tmux-thumbs
      ];
      shortcut = "a";
      terminal = "screen-256color";
      tmuxp.enable = true;
    };
  };
}
