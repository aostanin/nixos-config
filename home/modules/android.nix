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
    home.packages = with pkgs; [
      androidStudioPackages.beta
      pidcat
      scrcpy
    ];
  };
}
