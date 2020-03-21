{ pkgs, config, lib, ... }:

with lib;

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = false;
    withPython = false;
    withPython3 = false;
    withRuby = false;
    plugins = with pkgs.vimPlugins; [
      ctrlp-vim
      gruvbox
      lightline-vim
      nerdcommenter
      polyglot
      syntastic
      vim-fugitive
      vim-gitgutter
      vim-sensible
    ];
    extraConfig = readFile ./config;
  };
}
