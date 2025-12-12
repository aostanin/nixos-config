{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.localModules.desktop-darwin;
in {
  options.localModules.desktop-darwin = {
    enable = lib.mkEnableOption "desktop-darwin";
  };

  config = lib.mkIf cfg.enable {
    localModules = {
      alacritty.enable = lib.mkDefault true;
      firefox.enable = lib.mkDefault true;
    };

    home.packages = with pkgs; [
      karabiner-elements
      scroll-reverser
      slack
      thunderbird
      utm
    ];
  };
}
