{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules.gtk;
in {
  options.localModules.gtk = {
    enable = lib.mkEnableOption "gtk";
  };

  config = lib.mkIf cfg.enable {
    gtk = {
      enable = true;
      theme.name = "Adwaita-dark";
      iconTheme.name = "Adwaita";
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };

    home.sessionVariables = {
      # Workaround for GTK 3.0 theme not applied
      GTK_THEME = "Adwaita:dark";
    };

    home.pointerCursor = {
      name = "phinger-cursors";
      package = pkgs.phinger-cursors;
      size = 24;
      # Fix virt-manager crash https://github.com/NixOS/nixpkgs/issues/207496#issuecomment-1364940915
      gtk.enable = true;
      x11.enable = true;
    };
  };
}
