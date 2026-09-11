{
  inputs,
  pkgs,
}: {
  palettes = import ./palettes.nix;

  wallpaper = "${inputs.nixos-artwork}/wallpapers/nix-wallpaper-nineish-dark-gray.png";

  cursor = {
    name = "phinger-cursors-dark";
    package = pkgs.phinger-cursors;
    size = 24;
  };
}
