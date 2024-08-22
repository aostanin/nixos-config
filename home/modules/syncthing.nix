{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules.syncthing;
in {
  options.localModules.syncthing = {
    enable = lib.mkEnableOption "syncthing";
  };

  config = lib.mkIf cfg.enable {
    services.syncthing.enable = true;
  };
}
