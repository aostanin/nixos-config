{ config, pkgs, ... }:

let
  home-manager = builtins.fetchTarball {
    url = "https://github.com/rycee/home-manager/archive/release-19.09.tar.gz";
  };
in {
  imports = [
    "${home-manager}/nixos"
  ];

  home-manager.users.aostanin = import ./home.nix;
}
