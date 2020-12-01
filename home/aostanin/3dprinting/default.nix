{ pkgs, config, lib, ... }:

{
  home.packages = with pkgs; [
    cura
    freecad
    meshlab
    openscad
  ];
}
