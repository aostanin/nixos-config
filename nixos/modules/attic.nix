{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.localModules.attic;
  domain = config.localModules.traefik.domain;
in {
  options.localModules.attic = {
    enable = lib.mkEnableOption "attic binary cache server";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8092;
      description = "Local port atticd listens on.";
    };

    storageDir = lib.mkOption {
      type = lib.types.path;
      description = "Directory for the local chunk store (bulk cache data).";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."atticd/token_rs256_secret" = {};

    sops.templates."atticd.env".content = ''
      ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=${config.sops.placeholder."atticd/token_rs256_secret"}
    '';

    services.atticd = {
      enable = true;
      environmentFile = config.sops.templates."atticd.env".path;
      settings = {
        listen = "127.0.0.1:${toString cfg.port}";
        api-endpoint = "https://attic.${domain}/";
        compression.type = "zstd";
        storage = {
          type = "local";
          path = cfg.storageDir;
        };
        garbage-collection = {
          interval = "12 hours";
          default-retention-period = "6 months";
        };
      };
    };

    systemd.services.atticd = {
      after = ["zfs-mount.service"];
      # Claim the dataset mountpoint for the (dynamic) atticd user before start,
      # run as root via "+" since the unit drops CAP_CHOWN.
      serviceConfig.ExecStartPre = ["+${pkgs.coreutils}/bin/chown atticd:atticd ${cfg.storageDir}"];
    };

    localModules.ingress.attic = {
      port = cfg.port;
      default.enable = false;
      trusted.enable = true;
    };
  };
}
