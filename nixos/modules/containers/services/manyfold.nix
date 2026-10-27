{
  lib,
  config,
  ...
}: let
  name = "manyfold";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    uid = lib.mkOption {
      type = lib.types.int;
      default = config.localModules.containers.uid;
    };

    gid = lib.mkOption {
      type = lib.types.int;
      default = config.localModules.containers.gid;
    };

    volumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra volumes to bind to the container.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."containers/${name}/secret_key_base" = {};

    sops.templates."${name}.env".content = ''
      SECRET_KEY_BASE=${config.sops.placeholder."containers/${name}/secret_key_base"}
    '';

    localModules.containers.containers.${name} = {
      # The solo image bundles redis and uses SQLite in /config.
      raw.image = "ghcr.io/manyfold3d/manyfold-solo:latest";
      raw.environment = {
        PUID = toString cfg.uid;
        PGID = toString cfg.gid;
        WEB_CONCURRENCY = "0";
      };
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      volumes.config = {
        destination = "/config";
        user = toString cfg.uid;
        group = toString cfg.gid;
      };
      raw.volumes = cfg.volumes;
      proxy = {
        enable = true;
        port = 3214;
      };
    };
  };
}
