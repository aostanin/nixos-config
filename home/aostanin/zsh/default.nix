{ pkgs, config, lib, ... }:

with lib;
let
  secrets = import ../../../secrets;
in
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
      HOMEBREW_GITHUB_API_TOKEN = secrets.githubApiToken;
    };
    shellAliases = {
      ls = "${pkgs.exa}/bin/exa";
      ll = "ls -l";
      la = "ls -a";
      lt = "ls --tree";
      lla = "ls -la";
    };
  };
}
