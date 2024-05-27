{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules.electronics;
in {
  options.localModules.electronics = {
    enable = lib.mkEnableOption "electronics";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      kicad
      minipro
      pulseview
      sigrok-cli
    ];
  };
}
