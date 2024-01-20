{
  pkgs,
  config,
  lib,
  ...
}: {
  programs.obs-studio = {
    enable = true;
  };
}
