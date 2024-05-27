{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules.obs-studio;
in {
  options.localModules.obs-studio = {
    enable = lib.mkEnableOption "obs-studio";
  };

  config = lib.mkIf cfg.enable {
    programs.obs-studio = {
      enable = true;
    };
  };
}
