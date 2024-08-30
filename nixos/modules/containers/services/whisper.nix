{
  lib,
  config,
  ...
}: let
  name = "whisper";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    port = lib.mkOption {
      type = lib.types.int;
      default = 10300;
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "tiny-int8";
    };

    language = lib.mkOption {
      type = lib.types.str;
      default = "en";
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/rhasspy/wyoming-whisper:latest";
      raw.ports = ["${toString cfg.port}:10300"];
      volumes.data.destination = "/data";
      raw.cmd = ["--model" cfg.model "--language" cfg.language];
    };
  };
}
