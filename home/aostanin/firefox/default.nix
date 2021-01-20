{ pkgs, config, lib, ... }:
let
  defaultSettings = {
    "identity.sync.tokenserver.uri" = "***REMOVED***";
    "browser.aboutConfig.showWarning" = false;
    "browser.tabs.warnOnClose" = false;
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
