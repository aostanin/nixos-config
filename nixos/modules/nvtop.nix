{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.localModules.nvtop;
in {
  options.localModules.nvtop = {
    enable = lib.mkEnableOption "nvtop";

    package = lib.mkPackageOption pkgs.nvtopPackages "full" {};
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [cfg.package];
  };
}
