{ pkgs, config, lib, ... }:

{
  home.packages = with pkgs; [
    android-studio
    pidcat
    scrcpy
  ];
}
