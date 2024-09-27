{
  lib,
  config,
  ...
}: let
  name = "openedai-speech";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    enableNvidia = lib.mkOption {
      type = lib.types.bool;
      default = config.localModules.podman.enableNvidia;
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/matatonic/openedai-speech:latest";
      networks = ["ollama"];
      volumes = {
        config.destination = "/app/config";
        voices.destination = "/app/voices";
      };
      raw.extraOptions = lib.mkIf cfg.enableNvidia ["--device=nvidia.com/gpu=all"];
    };
  };
}
