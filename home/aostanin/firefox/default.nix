{ pkgs, config, lib, ... }:
let
  defaultSettings = {
    "identity.sync.tokenserver.uri" = "https://firefox-sync.ostan.in/token/1.0/sync/1.5";
    "browser.aboutConfig.showWarning" = false;
    "browser.tabs.warnOnClose" = false;

    # Performance
    "layers.acceleration.force-enabled" = true;
    "gfx.webrender.all" = true;
  };
in
{
  programs.firefox = {
    enable = true;
    profiles = {
      aostanin = {
        id = 0;
        settings = defaultSettings // { };
      };
      work = {
        id = 1;
        settings = defaultSettings // { };
      };
    };
    extensions = with pkgs.nur.repos.rycee.firefox-addons; [
      bitwarden
      clearurls
      decentraleyes
      h264ify
      https-everywhere
      i-dont-care-about-cookies
      multi-account-containers
      temporary-containers
      ublock-origin
      vimium
    ];
  };
}
