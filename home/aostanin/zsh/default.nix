{ pkgs, config, lib, ... }:

with lib;

{
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
    } // optionalAttrs pkgs.stdenv.isDarwin {
      HOMEBREW_GITHUB_API_TOKEN = "***REMOVED***";
    };
  };
}
