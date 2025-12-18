{pkgs, ...}: {
  localModules = {
    aerospace.enable = true;
    common.enable = true;
  };

  environment.systemPackages = [
    pkgs.nvtopPackages.apple
  ];
}
