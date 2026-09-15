{
  lib,
  config,
  ...
}: let
  name = "whisper-cpp";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    enableNvidia = lib.mkOption {
      type = lib.types.bool;
      default = config.localModules.podman.enableNvidia;
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 8080;
    };

    model = lib.mkOption {
      type = lib.types.str;
      # q5_0 scores like f16 here at ~900M VRAM instead of ~1.9G.
      default = "large-v3-turbo-q5_0";
      description = "ggml model name, as accepted by download-ggml-model.sh.";
    };

    language = lib.mkOption {
      type = lib.types.str;
      default = "auto";
    };

    threads = lib.mkOption {
      type = lib.types.int;
      default = 8;
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/ggml-org/whisper.cpp:main-cuda";
      # --inference-path is what makes /inference OpenAI-shaped.
      raw.cmd = [
        ''
          set -e
          test -f /models/ggml-${cfg.model}.bin \
            || /app/models/download-ggml-model.sh ${cfg.model} /models
          exec whisper-server \
            -m /models/ggml-${cfg.model}.bin \
            --host 0.0.0.0 --port ${toString cfg.port} \
            --inference-path /v1/audio/transcriptions \
            -l ${cfg.language} -t ${toString cfg.threads} \
            --convert --tmp-dir /tmp
        ''
      ];
      raw.extraOptions = lib.mkIf cfg.enableNvidia ["--device=nvidia.com/gpu=all"];
      volumes.models.destination = "/models";
      proxy = {
        enable = true;
        inherit (cfg) port;
      };
    };
  };
}
