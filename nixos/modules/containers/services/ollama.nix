{
  lib,
  config,
  ...
}: let
  name = "ollama";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    enableNvidia = lib.mkOption {
      type = lib.types.bool;
      default = config.localModules.podman.enableNvidia;
    };

    contextLength = lib.mkOption {
      type = lib.types.int;
      default = 64000;
      description = "Context window size for Ollama (OLLAMA_CONTEXT_LENGTH).";
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/ollama/ollama:latest";
      networks = ["ollama"];
      raw.ports = ["11434:11434"];
      raw.environment = {
        OLLAMA_CONTEXT_LENGTH = toString cfg.contextLength;
      };
      volumes = {
        data.destination = "/root/.ollama";
        models = {
          destination = "/root/.ollama/models";
          storageType = "bulk";
        };
      };
      raw.extraOptions = lib.mkIf cfg.enableNvidia ["--device=nvidia.com/gpu=all"];
    };
  };
}
