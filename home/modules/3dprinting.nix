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
      cura-appimage
      freecad
      meshlab
      openscad
    ];

    services.flatpak = {
      enable = true;
      packages = [
        rec {
          # OrcaSlicer from nixpkgs crashes with network printers
          # ref: https://github.com/NixOS/nixpkgs/issues/348751
          appId = "io.github.softfever.OrcaSlicer";
          sha256 = "0hdx5sg6fknj1pfnfxvlfwb5h6y1vjr6fyajbsnjph5gkp97c6p1";
          bundle = "${pkgs.fetchurl {
            url = "https://github.com/SoftFever/OrcaSlicer/releases/download/v2.3.0/OrcaSlicer-Linux-flatpak_V2.3.0_x86_64.flatpak";
            sha256 = sha256;
          }}";
        }
      ];
    };
  };
}
