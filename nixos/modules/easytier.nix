{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.localModules.easytier;
in {
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/networking/easytier.nix"
  ];

  options.localModules.easytier = {
    enable = lib.mkEnableOption "easytier";
  };

  config = lib.mkIf cfg.enable {
    services.easytier = {
      enable = true;
    };
  };
}
