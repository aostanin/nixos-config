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
    home.packages = with pkgs;
      [
        meshlab
        openscad
      ]
      ++ lib.optionals stdenv.isLinux [
        blender
        cura-appimage
        freecad
        # OrcaSlicer crashes with a network printer, so use the AppImage
        # ref: https://github.com/NixOS/nixpkgs/issues/348751
        orca-slicer-appimage
      ];
  };
}
