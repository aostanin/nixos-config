{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    ../../modules
  ];

  localModules.common = {
    enable = true;
    minimal = true;
  };
}
