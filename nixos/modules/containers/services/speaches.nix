{
  lib,
  config,
  ...
}: let
  name = "speaches";
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
      raw.image = "ghcr.io/speaches-ai/speaches:latest-${
        if cfg.enableNvidia
        then "cuda"
        else "cpu"
      }";
      # Work around strip_emojis() deleting all CJK, so Japanese/Chinese TTS
      # input survives to synthesis. Upstream fix (PR #610) is not released yet.
      raw.cmd = [
        "sh"
        "-c"
        "sed -i '/000024c2/d' /home/ubuntu/speaches/src/speaches/text_utils.py; exec uvicorn --factory speaches.main:create_app"
      ];
      raw.environment.WHISPER__COMPUTE_TYPE = "int8";
      volumes.cache = {
        destination = "/home/ubuntu/.cache/huggingface/hub";
        user = "1000";
        group = "1000";
      };
      raw.extraOptions = lib.mkIf cfg.enableNvidia ["--device=nvidia.com/gpu=all"];
      proxy = {
        enable = true;
        port = 8000;
      };
    };
  };
}
