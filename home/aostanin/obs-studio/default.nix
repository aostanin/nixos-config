{ pkgs, config, lib, ... }:

with lib;

{
  programs.obs-studio = {
    enable = true;
  };
}
