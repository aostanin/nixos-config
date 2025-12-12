{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.localModules.yabai;
in {
  options.localModules.yabai = {
    enable = lib.mkEnableOption "yabai";
  };

  config = lib.mkIf cfg.enable {
    services.yabai.enable = true;
  };
}
