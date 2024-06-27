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
    nvtopPkgs = with pkgs.nvtopPackages;
      lib.lists.concatMap (driver:
        if (driver == "amdgpu")
        then [amd]
        else if (driver == "nvidia")
        then [nvidia]
        else if driver == "modeseting"
        then [intel]
        else [])
      config.services.xserver.videoDrivers;
  in {
    environment.systemPackages =
      if (builtins.length nvtopPkgs > 1)
      then [pkgs.nvtopPackages.full]
      else nvtopPkgs;
  });
}
