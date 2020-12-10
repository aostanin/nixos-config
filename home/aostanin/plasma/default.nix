{ pkgs, config, lib, ... }:

{
  home.packages = with pkgs; [
    (ark.override { unfreeEnableUnrar = true; })
    gwenview
    kate
    krdc
    okular
    plasma-browser-integration
    spectacle
  ];
}
