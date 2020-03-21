{ pkgs, config, lib, ... }:

{
  programs.tmux = {
    enable = true;
    aggressiveResize = true;
    baseIndex = 1;
    clock24 = true;
    escapeTime = 0;
    keyMode = "vi";
    plugins = with pkgs.tmuxPlugins; [
      pain-control
    ];
    shortcut = "a";
    terminal = "screen-256color";
    tmuxp.enable = true;
  };
}
