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

    # Workaround for Ctrl+/ triggering system alert sound in Alacritty and other apps
    # ref: https://github.com/alacritty/alacritty/issues/3014#issuecomment-1659329460
    home.file."Library/KeyBindings/DefaultKeyBinding.dict".text = ''
      {
          "^/" = "noop:";
      }
    '';

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
