{pkgs, ...}: {
  localModules = {
    common.enable = true;

    vdirsyncer.enable = true;
  };

  home.packages = with pkgs; [
    beets
  ];
}
