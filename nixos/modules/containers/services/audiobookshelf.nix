{
  lib,
  config,
  ...
}: let
  name = "audiobookshelf";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    volumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra volumes to bind to the container.";
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/advplyr/audiobookshelf";
      volumes = {
        config.destination = "/config";
        metadata.destination = "/metadata";
      };
      raw.volumes = cfg.volumes;
      proxy = {
        enable = true;
      };
    };
  };
}
