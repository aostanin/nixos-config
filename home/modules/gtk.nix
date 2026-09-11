{
  pkgs,
  config,
  lib,
  theme,
  ...
}: let
  cfg = config.localModules.gtk;
in {
  options.localModules.gtk = {
    enable = lib.mkEnableOption "gtk";
  };

  config = lib.mkIf cfg.enable {
    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

    gtk = {
      enable = true;
      theme = {
        name = "Adwaita-dark";
        package = pkgs.gnome-themes-extra;
      };
      iconTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
      };
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };

    home.sessionVariables = {
      # Workaround for GTK 3.0 theme not applied
      GTK_THEME = "Adwaita:dark";
    };

    home.pointerCursor = {
      inherit (theme.cursor) name package size;
      gtk.enable = true;
      x11 = {
        enable = true;
        defaultCursor = theme.cursor.name;
      };
    };
  };
}
