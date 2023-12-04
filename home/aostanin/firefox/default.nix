{
  pkgs,
  config,
  lib,
  secrets,
  ...
}: {
  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
  };

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
          "full-screen-api.ignore-widgets" = true;

          # Needed for dark mode for simple-tab-groups
          "svg.context-properties.content.enabled" = true;

          # Privacy
          "privacy.query_stripping.enabled" = true;

          # Performance
          "layers.acceleration.force-enabled" = true;
          "gfx.webrender.all" = true;

          # Remove Ads
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.vpn_promo.enabled" = false;
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
          tree-style-tab
          ublock-origin
          vimium
        ];
      };
    };
  };
}
