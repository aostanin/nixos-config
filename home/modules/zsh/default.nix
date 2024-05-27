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
      enableAutosuggestions = true;
      oh-my-zsh = {
        enable = true;
        plugins = [
          "vi-mode"
        ];
      };
      initExtra = ''
        autoload zmv
        source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh
        source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        export PATH=$HOME/.local/bin:$PATH
      '';
      localVariables = {
        CASE_SENSITIVE = "true";
        DISABLE_AUTO_UPDATE = "true";
      };
      shellAliases = {
        ncdu = "ncdu --color dark";
      };
    };
  };
}
