{
  lib,
  config,
  ...
}: let
  name = "wyoming-openai";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    port = lib.mkOption {
      type = lib.types.int;
      default = 10300;
    };

    openaiUrl = lib.mkOption {
      type = lib.types.str;
      description = "OpenAI-compatible base URL (LiteLLM) for both STT and TTS.";
    };

    sttModels = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "STT model names as exposed by the backend.";
    };

    ttsModels = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "TTS model names as exposed by the backend.";
    };

    ttsVoices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "TTS voices to advertise (empty = autodetect).";
    };

    languages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["en"];
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."containers/litellm/master_key" = {};

    sops.templates."${name}.env".content = ''
      STT_OPENAI_KEY=${config.sops.placeholder."containers/litellm/master_key"}
      TTS_OPENAI_KEY=${config.sops.placeholder."containers/litellm/master_key"}
    '';

    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/roryeckel/wyoming_openai:latest";
      raw.ports = ["${toString cfg.port}:10300"];
      raw.environment = {
        WYOMING_URI = "tcp://0.0.0.0:10300";
        STT_OPENAI_URL = cfg.openaiUrl;
        TTS_OPENAI_URL = cfg.openaiUrl;
        STT_MODELS = lib.concatStringsSep " " cfg.sttModels;
        TTS_MODELS = lib.concatStringsSep " " cfg.ttsModels;
        TTS_VOICES = lib.concatStringsSep " " cfg.ttsVoices;
        WYOMING_LANGUAGES = lib.concatStringsSep " " cfg.languages;
      };
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
    };
  };
}
