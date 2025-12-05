{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.localModules.easytier;
in {
  options.localModules.easytier = {
    enable = lib.mkEnableOption "easytier";
  };

  config = lib.mkIf cfg.enable {
    services.easytier = {
      enable = true;
    };
  };
}
