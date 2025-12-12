{pkgs, ...}: {
  localModules = {
    common.enable = true;

    yabai.enable = true;
  };

  environment.systemPackages = [
    pkgs.nvtopPackages.apple
  ];
}
