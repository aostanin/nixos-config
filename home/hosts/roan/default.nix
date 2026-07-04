{
  pkgs,
  config,
  lib,
  ...
}: {
  localModules = {
    common.enable = true;
    gnupg.enable = true;
  };
}
