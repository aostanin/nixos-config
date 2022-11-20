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
  };
}
