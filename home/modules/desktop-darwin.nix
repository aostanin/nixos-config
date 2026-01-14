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
      syncthing.enable = lib.mkDefault true;
    };

    home.packages = with pkgs; [
      scroll-reverser
      thunderbird
      utm

      # Chat
      element-desktop
      slack
    ];
  };
}
