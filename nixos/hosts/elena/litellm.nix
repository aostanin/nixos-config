{secrets, ...}: let
  llamaCppApiBase = "https://llama-cpp.${secrets.domain}/v1";
  whisperCppApiBase = "https://whisper-cpp.${secrets.domain}/v1";
  kokoroApiBase = "https://kokoro-fastapi.${secrets.domain}/v1";

  mkLlamaCppModel = model_name: llamaModel: {
    inherit model_name;
    litellm_params = {
      model = "openai/${llamaModel}";
      api_base = llamaCppApiBase;
      api_key = "none";
    };
  };

  ornith9b = "ornith-ai/Ornith-1.5-9B-GGUF:Q4_K_M";
in {
  localModules.containers.services.litellm = {
    enable = true;
    models = [
      (mkLlamaCppModel "qwen3.8-27b" "unsloth/Qwen3.8-27B-GGUF:Q4_K_XL")
      (mkLlamaCppModel "ornith-1.5-9b" ornith9b)
      {
        model_name = "ha-assist";
        litellm_params = {
          model = "openai/${ornith9b}";
          api_base = llamaCppApiBase;
          api_key = "none";
          extra_body.chat_template_kwargs.enable_thinking = false;
        };
      }
      {
        model_name = "whisper";
        litellm_params = {
          # whisper-server picks its model at startup and ignores this.
          model = "openai/whisper-1";
          api_base = whisperCppApiBase;
          api_key = "none";
        };
        model_info.mode = "audio_transcription";
      }
      {
        model_name = "kokoro";
        litellm_params = {
          model = "openai/kokoro";
          api_base = kokoroApiBase;
          api_key = "none";
        };
      }
    ];
  };
}
