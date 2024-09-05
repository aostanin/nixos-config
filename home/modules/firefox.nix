{
  pkgs,
  config,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules.firefox;
in {
  options.localModules.firefox = {
    enable = lib.mkEnableOption "firefox";
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      BROWSER = "firefox";
      MOZ_ENABLE_WAYLAND = "1";
    };

    programs.firefox = {
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
          extensions = with pkgs.nur.repos.rycee.firefox-addons; [
            pkgs.nur.repos.rycee.firefox-addons."10ten-ja-reader"
            auto-tab-discard
            bitwarden
            cookies-txt
            libredirect
            multi-account-containers
            simple-tab-groups
            sponsorblock
            statshunters
            temporary-containers
            ublock-origin
            vimium
          ];
        };
      };
    };
  };
}
