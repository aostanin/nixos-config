{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules.qt;
in {
  options.localModules.qt = {
    enable = lib.mkEnableOption "qt";
  };

  config = lib.mkIf cfg.enable {
    qt = {
      enable = true;
      platformTheme.name = "kde";
      style = {
        name = "adwaita-dark";
        package = pkgs.adwaita-qt;
      };
    };
  };
}
