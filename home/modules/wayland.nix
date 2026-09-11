{
  pkgs,
  config,
  lib,
  theme,
  ...
}: let
  cfg = config.localModules.wayland;
in {
  options.localModules.wayland = {
    enable = lib.mkEnableOption "wayland desktop session";

    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = theme.wallpaper;
      description = ''
        The wallpaper image to use by default.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    localModules = {
      niri.enable = true;
      noctalia.enable = true;
    };

    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        waylandFrontend = true;
        addons = with pkgs; [
          fcitx5-mozc
        ];
      };
    };

    xsession = {
      enable = true;
      preferStatusNotifierItems = true;
    };

    home.packages = with pkgs; [
      pavucontrol
      wayvnc
      wdisplays
    ];

    services = {
      kdeconnect = {
        enable = true;
        indicator = true;
      };
    };
  };
}
