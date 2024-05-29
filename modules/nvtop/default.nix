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
  };

  config = lib.mkIf cfg.enable (let
    nvtopPkgs = lib.lists.concatMap (driver:
      if (driver == "amdgpu")
      then [pkgs.nvtop-amd]
      else if (driver == "nvidia")
      then [pkgs.nvtop-nvidia]
      else if driver == "modeseting"
      then [pkgs.nvtop-intel]
      else [])
    config.services.xserver.videoDrivers;
  in {
    environment.systemPackages =
      if (builtins.length nvtopPkgs > 1)
      then [pkgs.nvtop]
      else nvtopPkgs;
  });
}
