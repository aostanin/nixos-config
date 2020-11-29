{ pkgs, config, lib, ... }:

{
  home.packages = with pkgs; [
    cura
    openscad
  ];
}
