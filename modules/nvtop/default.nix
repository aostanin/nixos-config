{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.localModules.nvtop;
in {
  options.localModules.nvtop = {
    enable = mkEnableOption "nvtop";
  };

  config = mkIf cfg.enable (let
    nvtopPkgs = with pkgs;
      lib.lists.concatMap (driver:
        if (driver == "amdgpu")
        then [nvtop-amd]
        else if (driver == "nvidia")
        then [nvtop-nvidia]
        else if driver == "modeseting"
        then [nvtop-intel]
        else [])
      config.services.xserver.videoDrivers;
  in {
    environment.systemPackages =
      if (builtins.length nvtopPkgs > 1)
      then [nvtop]
      else nvtopPkgs;
  });
}
