{
  lib,
  config,
  ...
}: let
  name = "kokoro-fastapi";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    enableNvidia = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 8880;
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/remsky/kokoro-fastapi-${
        if cfg.enableNvidia
        then "gpu"
        else "cpu"
      }:latest";
      raw.extraOptions = lib.mkIf cfg.enableNvidia ["--device=nvidia.com/gpu=all"];
      proxy = {
        enable = true;
        inherit (cfg) port;
      };
    };
  };
}
