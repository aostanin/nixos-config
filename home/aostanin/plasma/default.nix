{ pkgs, config, lib, ... }:

{
  home.packages = with pkgs; [
    (ark.override { unfreeEnableUnrar = true; })
    gwenview
    kate
    kdeconnect
    krdc
    okular
    plasma-browser-integration
    spectacle
  ];

  home.file = {
    ".local/share/konsole/Gruvbox_dark.colorscheme".source = ./Gruvbox_dark.colorscheme;
    ".local/share/konsole/Profile 1.profile".source = ./Profile_1.profile;
  };
}