{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules.video;
in {
  options.localModules.video = {
    enable = lib.mkEnableOption "video";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      handbrake
      kdePackages.kdenlive
      losslesscut-bin
    ];
  };
}
