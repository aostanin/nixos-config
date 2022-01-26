{ pkgs, config, lib, ... }:
let
  secrets = import ../../../secrets;
  defaultSettings = {
    "identity.sync.tokenserver.uri" = secrets.firefox.syncUrl;
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

  xdg.desktopEntries.firefox-work = {
    name = "Firefox (Work)";
    genericName = "Web Browser";
    exec = "firefox -P work %U";
    icon = "firefox";
    terminal = false;
    type = "Application";
    categories = [ "Network" "WebBrowser" ];
  };
}
