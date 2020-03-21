{ pkgs, config, lib, ... }:

{
  home.packages = with pkgs; [
    unstable.android-studio
    pidcat
    scrcpy
  ];
}
