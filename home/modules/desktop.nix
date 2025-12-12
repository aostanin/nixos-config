{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.localModules.desktop;
in {
  options.localModules.desktop = {
    enable = lib.mkEnableOption "desktop";
  };

  config = lib.mkIf cfg.enable {
    localModules = {
      desktop-linux.enable = lib.mkDefault (!pkgs.stdenv.isDarwin);
      desktop-darwin.enable = lib.mkDefault pkgs.stdenv.isDarwin;
    };
  };
}
