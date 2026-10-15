{
  pkgs,
  config,
  lib,
  ...
}: {
  localModules = {
    common = {
      enable = true;
      enableNvidia = true;
    };

    desktop.enable = true;

    gaming.enable = true;
  };
}
