{
  pkgs,
  config,
  lib,
  ...
}: {
  localModules = {
    common.enable = true;
    email.enable = true;
    gnupg.enable = true;
  };
}
