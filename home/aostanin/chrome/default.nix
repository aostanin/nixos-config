{ pkgs, config, lib, ... }:

{
  programs.google-chrome.enable = true;

  xdg.configFile."chrome-flags.conf".text = ''
    --password-store=gnome
  '';
}
