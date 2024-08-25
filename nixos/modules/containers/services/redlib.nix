{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "redlib";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption "libreddit" {};

    subscriptions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
  };

  config = lib.mkIf (config.localModules.containers.enable && cfg.enable) {
    localModules.containers.services.${name} = {
      autoupdate = lib.mkDefault true;
      proxy = {
        enable = lib.mkDefault true;
        tailscale.enable = lib.mkDefault true;
        lan.enable = lib.mkDefault true;
        net = {
          enable = lib.mkDefault true;
          auth = lib.mkDefault "authelia";
        };
      };
    };

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "quay.io/redlib/redlib:latest";
        environment = {
          REDLIB_DEFAULT_THEME = "doomone";
          REDLIB_DEFAULT_SHOW_NSFW = "on";
          REDLIB_DEFAULT_USE_HLS = "on";
          REDLIB_DISABLE_VISIT_REDDIT_CONFIRMATION = "on";
          REDLIB_DEFAULT_SUBSCRIPTIONS = builtins.concatStringsSep "+" cfg.subscriptions;
        };
      }
      mkContainerDefaultConfig
      (mkContainerProxyConfig name cfg.proxy)
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.services."podman-${name}" = mkServiceProxyConfig name cfg.proxy;
  };
}
