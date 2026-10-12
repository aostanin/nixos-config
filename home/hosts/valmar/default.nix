{
  pkgs,
  config,
  lib,
  ...
}: {
  localModules = {
    common.enable = true;

    desktop.enable = true;

    gaming.enable = true;
  };
}
