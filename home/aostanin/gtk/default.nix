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
}
