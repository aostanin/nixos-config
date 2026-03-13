{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules.android;
in {
  options.localModules.android = {
    enable = lib.mkEnableOption "android";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs;
      [
        pidcat
        scrcpy
      ]
      ++ lib.optionals stdenv.isx86_64 [
        androidStudioPackages.beta
      ];
  };
}
