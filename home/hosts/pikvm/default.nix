{
  pkgs,
  config,
  lib,
  ...
}: {
  localModules.common = {
    enable = true;
    minimal = true;
  };
}
