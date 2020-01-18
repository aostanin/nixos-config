{ config, pkgs, ... }:

{
  imports = [
    <home-manager/nixos>
  ];

  home-manager.users.root = import ./root/home.nix;
  home-manager.users.aostanin = (import ./aostanin/home.nix) config;
}
