{ config, pkgs, ... }:

let
  home-manager = builtins.fetchTarball {
    url = "https://github.com/rycee/home-manager/archive/master.tar.gz";
  };
in {
  imports = [
    "${home-manager}/nixos"
  ];

  home-manager.users.root = import ./root/home.nix;
  home-manager.users.aostanin = import ./aostanin/home.nix;
}
