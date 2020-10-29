{ pkgs, config, lib, ... }:

{
  # TODO: Switch to Chromium?
  programs.google-chrome = {
    enable = true;
  };
}
