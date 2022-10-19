{ pkgs, config, lib, ... }:
let
  secrets = import ../../../secrets;
in
{
  programs.firefox = {
    enable = true;
    profiles = {
      aostanin = {
        id = 0;
        settings = {
          "browser.aboutConfig.showWarning" = false;
          "browser.tabs.warnOnClose" = false;
          "extensions.pocket.enabled" = false;
          "general.autoScroll" = false;

          # Fixed location ref: https://security.stackexchange.com/a/147176
          "geo.provider.network.url" = "data:application/json,{\"location\": {\"lat\": ${toString secrets.location.coarse.latitude}, \"lng\": ${toString secrets.location.coarse.longitude}}, \"accuracy\": 27000.0}";

          # Needed for dark mode for simple-tab-groups
          "svg.context-properties.content.enabled" = true;

          # Privacy
          "privacy.query_stripping.enabled" = true;

          # Performance
          "layers.acceleration.force-enabled" = true;
          "gfx.webrender.all" = true;
        };
      };
    };
    extensions = with pkgs.nur.repos.rycee.firefox-addons; [
      pkgs.nur.repos.rycee.firefox-addons."10ten-ja-reader"
      bitwarden
      cookies-txt
      multi-account-containers
      simple-tab-groups
      sponsorblock
      statshunters
      temporary-containers
      ublock-origin
      vimium
    ];
  };
}
