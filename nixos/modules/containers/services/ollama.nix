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
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/ollama/ollama:latest";
      networks = ["ollama"];
      raw.ports = ["11434:11434"];
      volumes = {
        data.destination = "/root/.ollama";
        models = {
          destination = "/root/.ollama/models";
          storageType = "bulk";
        };
      };
      raw.extraOptions = ["--device=nvidia.com/gpu=all"];
    };
  };
}
