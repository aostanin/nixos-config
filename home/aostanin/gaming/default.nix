{
  pkgs,
  config,
  lib,
  nixpkgs-yuzu,
  ...
}: {
  home.packages = with pkgs; [
    # Tools
    bottles
    gamescope
    mangohud
    pegasus-frontend

    # Emulators
    cemu
    dolphin-emu
    retroarch # TODO: Add cores?
    nixpkgs-yuzu.yuzu
  ];
}
