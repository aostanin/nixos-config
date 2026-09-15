{
  lib,
  config,
  ...
}: let
  name = "wyoming-openai";
  cfg = config.localModules.containers.services.${name};
  masterKey = config.sops.placeholder."containers/litellm/master_key";
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
      default = [];
      description = "STT model names as exposed by the backend. Empty advertises no ASR.";
    };

    ttsModels = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "TTS model names as exposed by the backend. Empty advertises no TTS.";
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
    assertions = [
      {
        assertion = cfg.sttModels != [] || cfg.ttsModels != [];
        message = "localModules.containers.services.${name}: set sttModels, ttsModels or both, otherwise it advertises nothing.";
      }
    ];

    sops.secrets."containers/litellm/master_key" = {};

    sops.templates."${name}.env".content =
      lib.concatMapStrings (l: l + "\n")
      (lib.optional (cfg.sttModels != []) "STT_OPENAI_KEY=${masterKey}"
        ++ lib.optional (cfg.ttsModels != []) "TTS_OPENAI_KEY=${masterKey}");

    localModules.containers.containers.${name} = {
      networks = ["proxy"];
      raw.image = "ghcr.io/roryeckel/wyoming_openai:latest";
      raw.ports = ["${toString cfg.port}:10300"];
      raw.environment =
        {
          WYOMING_URI = "tcp://0.0.0.0:10300";
          WYOMING_LANGUAGES = lib.concatStringsSep " " cfg.languages;
        }
        // lib.optionalAttrs (cfg.sttModels != []) {
          STT_OPENAI_URL = cfg.openaiUrl;
          STT_MODELS = lib.concatStringsSep " " cfg.sttModels;
        }
        // lib.optionalAttrs (cfg.ttsModels != []) {
          TTS_OPENAI_URL = cfg.openaiUrl;
          TTS_MODELS = lib.concatStringsSep " " cfg.ttsModels;
          TTS_VOICES = lib.concatStringsSep " " cfg.ttsVoices;
        };
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
    };
  };
}
