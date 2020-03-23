{ pkgs, config, lib, ... }:

{
  services.dunst = {
    enable = true;
    settings = {
      global = {
        markup = "full";
        format = "<b>%s</b>\n%b";
        icon_position = "left";
        max_icon_size = 32;
        sort = true;
        indicate_hidden = true;
        alignment = "left";
        bounce_freq = 0;
        show_age_threshold = 60;
        word_wrap = true;
        ignore_newline = false;
        geometry = "300x5-30+50";
        transparency = 10;
        idle_threshold = 90;
        follow = "mouse";
        sticky_history = true;
        line_height = 0;
        separator_height = 2;
        padding = 8;
        horizontal_padding = 8;
        startup_notification = false;
        frame_width = 1;
        frame_color = "#d5c4a1";
        separator_color = "#d5c4a1";
      };
      shortcuts = {
        close = "ctrl+space";
        close_all = "ctrl+shift+space";
        history = "ctrl+grave";
        context = "ctrl+shift+period";
      };
      urgency_low = {
        background = "#3c3836";
        foreground = "#665c54";
        timeout = 10;
      };
      urgency_normal = {
        background = "#504945";
        foreground = "#d5c4a1";
        timeout = 10;
      };
      urgency_critical = {
        background = "#fb4934";
        foreground = "#ebdbb2";
        timeout = 0;
      };
    };
  };
}
