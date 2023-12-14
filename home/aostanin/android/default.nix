{
  pkgs,
  config,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    androidStudioPackages.beta
    pidcat
    scrcpy
  ];
}
