{
  lib,
  config,
  ...
}: let
  name = "redlib";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    subscriptions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/silvenga/redlib:latest";
      raw.environment = {
        REDLIB_DEFAULT_THEME = "doomone";
        REDLIB_DEFAULT_SHOW_NSFW = "on";
        REDLIB_DEFAULT_USE_HLS = "on";
        REDLIB_DEFAULT_DISABLE_VISIT_REDDIT_CONFIRMATION = "on";
        REDLIB_DEFAULT_REMOVE_DEFAULT_FEEDS = "on";
        REDLIB_DEFAULT_SUBSCRIPTIONS = builtins.concatStringsSep "+" cfg.subscriptions;
      };
      proxy = {
        enable = true;
        names = ["libreddit"];
        default.enable = true;
        default.auth = "authelia";
      };
    };
  };
}
