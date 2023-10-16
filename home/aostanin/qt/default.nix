{
  pkgs,
  config,
  lib,
  ...
}: {
  qt = {
    enable = true;
    # TODO: Switch to "kde" https://github.com/nix-community/home-manager/pull/4085
    # Issue with Gnome: https://unix.stackexchange.com/questions/502722/dolphin-background-and-font-color-are-both-white/683366#683366
    platformTheme = "gnome";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };
}
