{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules.zsh;
in {
  options.localModules.zsh = {
    enable = lib.mkEnableOption "zsh";
  };

  config = lib.mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      historySubstringSearch.enable = true;
      syntaxHighlighting.enable = true;
      oh-my-zsh.enable = true;
      plugins = [
        {
          name = "vi-mode";
          src = pkgs.zsh-vi-mode;
          file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
        }
      ];
      localVariables = {
        CASE_SENSITIVE = "true";
        DISABLE_AUTO_UPDATE = "true";
      };
      shellAliases = {
        ncdu = "gdu";
      };
    };
  };
}
