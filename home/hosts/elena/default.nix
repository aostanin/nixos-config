{pkgs, ...}: {
  localModules = {
    common = {
      enable = true;
      enableNvidia = true;
    };

    vdirsyncer.enable = true;
  };

  home.packages = with pkgs; [
    beets
  ];
}
