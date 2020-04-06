{ pkgs, config, lib, ... }:

{
  home.packages = with pkgs; [
    kicad
    pulseview
    sigrok-cli
  ];
}
