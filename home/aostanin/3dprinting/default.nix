{
  pkgs,
  config,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    blender
    (cura.override {plugins = with pkgs.curaPlugins; [octoprint];})
    freecad
    meshlab
    openscad
    prusa-slicer
  ];
}
