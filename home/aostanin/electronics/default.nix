{ pkgs, config, lib, ... }:

{
  home.packages = with pkgs; [
    kicad
    minipro
    pulseview
    sigrok-cli
  ];
}
