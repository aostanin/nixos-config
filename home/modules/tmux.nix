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
        set -g set-clipboard on
        set -s extended-keys on
        set -g extended-keys-format csi-u
        set -as terminal-features 'xterm*:extkeys'
        set -as terminal-features 'xterm*:hyperlinks'
        set -as terminal-features 'xterm*:usstyle'
        set -as terminal-features 'xterm*:sync'
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
      terminal = "tmux-256color";
      tmuxp.enable = true;
    };
  };
}
