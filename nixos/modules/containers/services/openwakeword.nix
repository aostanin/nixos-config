{
  lib,
  config,
  ...
}: let
  name = "openwakeword";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    port = lib.mkOption {
      type = lib.types.int;
      default = 10400;
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "ok_nabu";
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/rhasspy/wyoming-openwakeword:latest";
      raw.ports = ["${toString cfg.port}:10400"];
      volumes.custom.destination = "/custom";
      raw.cmd = ["--preload-model" cfg.model "--custom-model-dir" "/custom"];
    };
  };
}
