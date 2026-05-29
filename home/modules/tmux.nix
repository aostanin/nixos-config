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
      focusEvents = true;
      historyLimit = 50000;
      sensibleOnTop = true;
      extraConfig = ''
        set -g allow-passthrough on
        set -g set-clipboard on
        set -s extended-keys on
        set -g extended-keys-format csi-u
        set -as terminal-features 'xterm*:extkeys'
        set -as terminal-features 'xterm*:hyperlinks'
        set -as terminal-features 'xterm*:usstyle'
        set -as terminal-features 'xterm*:sync'
        set -g renumber-windows on

        set -g set-titles on
        set -g set-titles-string "#h: #S / #W"

        bind-key C-a last-window
        bind-key a send-prefix

        bind-key b break-pane -d
        bind-key B choose-window "join-pane -h -s '%%'"
      '';
      keyMode = "vi";
      mouse = true;
      plugins = with pkgs.tmuxPlugins; [
        {
          plugin = gruvbox;
          extraConfig = ''
            set -g @tmux-gruvbox 'dark'
            set -g @tmux-gruvbox-right-status-z '#h #{tmux_mode_indicator}'
          '';
        }
        pain-control
        {
          plugin = tmux-floax;
          extraConfig = ''
            set -g @floax-width '80%'
            set -g @floax-height '80%'
            set -g @floax-change-path 'true'
            set -g @floax-border-color 'green'
          '';
        }
        {
          plugin = fingers;
          extraConfig = ''
            set -g @fingers-key O
          '';
        }
        mode-indicator
      ];
      shortcut = "a";
      terminal = "tmux-256color";
      tmuxp.enable = true;
    };

    programs.fzf.tmux.enableShellIntegration = true;

    programs.sesh = {
      enable = true;
      settings = {
        dir_length = 2;
        blacklist = ["scratch"];
        default_session = {
          startup_command = " [ -f .smug.yml ] && smug start -f .smug.yml -i && tmux kill-window -t ${toString config.programs.tmux.baseIndex} || clear";
        };
      };
    };

    programs.smug.enable = true;
  };
}
