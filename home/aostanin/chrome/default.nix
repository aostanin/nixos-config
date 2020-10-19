{ pkgs, config, lib, ... }:

{
  # TODO: Switch to Chromium?
  programs.google-chrome = {
    enable = true;
    package = pkgs.google-chrome.override {
      # Disable Nvidia screen corruption https://askubuntu.com/a/1275573
      commandLineArgs = "--use-cmd-decoder=validating --use-gl=desktop";
    };
  };
}
