{
  lib,
  config,
  ...
}: let
  name = "piper";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    port = lib.mkOption {
      type = lib.types.int;
      default = 10200;
    };

    voice = lib.mkOption {
      type = lib.types.str;
      default = "en_GB-cori-high";
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/rhasspy/wyoming-piper:latest";
      raw.ports = ["${toString cfg.port}:10200"];
      volumes.data.destination = "/data";
      raw.cmd = [
        "--data-dir"
        "/data"
        "--voice"
        cfg.voice
      ];
    };
  };
}
