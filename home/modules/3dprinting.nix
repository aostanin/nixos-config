{
  pkgs,
  config,
  lib,
  localLib,
  ...
}: let
  cfg = config.localModules."3dprinting";
in {
  options.localModules."3dprinting" = {
    enable = lib.mkEnableOption "3dprinting";
  };

  config = lib.mkIf cfg.enable {
    home.packages = localLib.filterAvailable (with pkgs; [
      (localLib.brokenOnDarwin blender)
      cura-appimage
      (localLib.brokenOnDarwin f3d)
      freecad
      meshlab
      (localLib.brokenOnDarwin openscad-unstable)
      orca-slicer
    ]);
  };
}
