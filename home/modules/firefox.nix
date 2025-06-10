{
  pkgs,
  config,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules.firefox;

  settings = {
    enable = true;
    profiles = {
      ${secrets.user.username} = {
        id = 0;
        settings = {
          "browser.aboutConfig.showWarning" = false;
          "browser.tabs.warnOnClose" = false;
          "extensions.pocket.enabled" = false;
          "general.autoScroll" = false;
          "full-screen-api.ignore-widgets" = true;
          "sidebar.verticalTabs" = true;

          "browser.ml.chat.enabled" = true;
          "browser.ml.chat.provider" = "https://chatgpt.com";

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

          # Disable two-finger swipe to go forward/back
          "browser.gesture.swipe.left" = "cmd_scrollLeft";
          "browser.gesture.swipe.right" = "cmd_scrollRight";
        };
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          pkgs.nur.repos.rycee.firefox-addons."10ten-ja-reader"
          auto-tab-discard
          bitwarden
          keepa
          libredirect
          multi-account-containers
          simple-tab-groups
          sponsorblock
          statshunters
          ublock-origin
          vimium
        ];
      };
    };
  };
in {
  options.localModules.firefox = {
    enable = lib.mkEnableOption "firefox";
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      BROWSER = "firefox";
      MOZ_ENABLE_WAYLAND = "1";
    };

    programs.firefox = settings;
  };
}
