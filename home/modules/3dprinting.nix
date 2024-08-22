{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules."3dprinting";
in {
  options.localModules."3dprinting" = {
    enable = lib.mkEnableOption "3dprinting";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      blender
      (cura.override {plugins = with pkgs.curaPlugins; [octoprint];})
      freecad
      meshlab
      openscad
      prusa-slicer
    ];
  };
}
