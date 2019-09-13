{ config, pkgs, ... }:

{
  services.syncthing = {
    enable = true;
    user = "aostanin";
    configDir = "/home/aostanin/.config/syncthing";
    dataDir = "/home/aostanin";
  };
}
