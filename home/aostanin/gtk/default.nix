{
  pkgs,
  config,
  lib,
  ...
}: {
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
    # Fix virt-manager crash https://github.com/NixOS/nixpkgs/issues/207496#issuecomment-1364940915
    gtk.enable = true;
    package = pkgs.vanilla-dmz;
    name = "Vanilla-DMZ";
  };
}
