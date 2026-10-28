{secrets, ...}: let
  port = 8087;
in {
  services.redlib = {
    enable = true;
    address = "127.0.0.1";
    inherit port;
    settings = {
      REDLIB_ENABLE_RSS = true;
      REDLIB_DEFAULT_THEME = "doomone";
      REDLIB_DEFAULT_SHOW_NSFW = true;
      REDLIB_DEFAULT_USE_HLS = true;
      REDLIB_DEFAULT_DISABLE_VISIT_REDDIT_CONFIRMATION = true;
      REDLIB_DEFAULT_SUBSCRIPTIONS = builtins.concatStringsSep "+" secrets.redlib.subscriptions;
    };
  };

  localModules.ingress.libreddit.port = port;
}
