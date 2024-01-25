{
  pkgs,
  config,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    # Tools
    bottles
    unstable.emulationstation-de
    gamescope
    mangohud
    pegasus-frontend

    # Emulators
    cemu
    retroarch # TODO: Add cores?
    unstable.yuzu
  ];
}
