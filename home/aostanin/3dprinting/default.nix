{ pkgs, config, lib, ... }:

{
  home.packages = with pkgs; [
    blender
    cura
    freecad
    meshlab
    openscad
    prusa-slicer
  ];
}
