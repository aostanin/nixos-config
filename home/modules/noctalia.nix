{
  config,
  lib,
  ...
}: let
  cfg = config.localModules.noctalia;
  waylandCfg = config.localModules.wayland;
in {
  options.localModules.noctalia = {
    enable = lib.mkEnableOption "noctalia-shell";
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets = {
        "nextcloud/url" = {};
        "nextcloud/username" = {};
        "nextcloud/password" = {};
      };

      templates."noctalia-calendar.toml".content = ''
        [calendar.account.nextcloud]
        type = "caldav"
        name = "Nextcloud"
        provider = "custom"
        # CalDAV discovery returns 405 without the dav endpoint.
        server_url = "${config.sops.placeholder."nextcloud/url"}remote.php/dav"
        username = "${config.sops.placeholder."nextcloud/username"}"
        credential_source = "file"
        password_file = "${config.sops.secrets."nextcloud/password".path}"
      '';
    };

    xdg.configFile."noctalia/calendar.toml".source =
      config.lib.file.mkOutOfStoreSymlink
      config.sops.templates."noctalia-calendar.toml".path;

    programs.noctalia = {
      enable = true;
      systemd.enable = true;

      settings = {
        bar.default = {
          concave_edge_corners = false;
          margin_ends = 0;
          position = "top";
          start = ["workspaces"];
          end = [
            "media"
            "tray"
            "notifications"
            "clipboard"
            "network"
            "bluetooth"
            "volume"
            "brightness"
            "caffeine"
            "battery"
            "session"
          ];
          thickness = 24;
        };

        backdrop.enabled = true;

        calendar = {
          enabled = true;
          refresh_minutes = 15;
        };

        control_center.width = 900;

        desktop_widgets.enabled = false;

        idle.behavior."screen-off" = {
          # Without `action` the behaviour is silently ignored.
          action = "screen_off";
          enabled = true;
          timeout = 300.0;
        };

        plugins = {
          enabled = [];
          auto_update = "none";
          source = [
            {
              name = "official";
              kind = "git";
              location = "https://github.com/noctalia-dev/official-plugins";
              enabled = false;
            }
            {
              name = "community";
              kind = "git";
              location = "https://github.com/noctalia-dev/community-plugins";
              enabled = false;
            }
          ];
        };

        shell = {
          settings_show_advanced = false;

          screenshot = {
            annotate = true;
            copy_to_clipboard = true;
            save_to_file = false;
          };

          launcher = {
            categories = false;
            compact = true;
            show_app_origin_indicator = false;
            sort_by_usage = false;
          };
        };

        system.monitor.enabled = false;

        theme = {
          builtin = "Gruvbox";
          source = "builtin";
          mode = "dark";
        };

        wallpaper = lib.mkIf (waylandCfg.wallpaper != null) {
          default.path = waylandCfg.wallpaper;
        };

        weather.enabled = false;

        widget = {
          clock.format = "{:%H:%M}";

          media.hide_when_no_media = true;
          workspaces = {
            hide_when_empty = true;
            # "id" is the per-monitor index, not the declared workspace name.
            label_source = "name";
          };

          network.show_label = false;
          volume.show_label = false;
          brightness.show_label = false;
        };
      };
    };
  };
}
