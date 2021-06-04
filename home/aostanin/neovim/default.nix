{ pkgs, config, lib, ... }:
let
  vim-openscad = pkgs.vimUtils.buildVimPlugin {
    pname = "vim-openscad";
    version = "2020-07-08";
    src = pkgs.fetchFromGitHub {
      owner = "sirtaj";
      repo = "vim-openscad";
      rev = "81db508b1888fdbea994d43ccef1acd86c8af3f7";
      sha256 = "1wcdfayjpb9h0lzwdi5nda4c0ch263fdr0379l9k1gf47bgq9cx2";
    };
  };
in
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = false;
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
      vim-openscad
      vim-sensible
    ];
    extraConfig = lib.readFile ./config;
  };
}
