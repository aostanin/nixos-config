{secrets, ...}: let
  llamaCppApiBase = "https://llama-cpp.${secrets.domain}/v1";
  speachesApiBase = "https://speaches.${secrets.domain}/v1";

  mkLlamaCppModel = model_name: llamaModel: {
    inherit model_name;
    litellm_params = {
      model = "openai/${llamaModel}";
      api_base = llamaCppApiBase;
      api_key = "none";
    };
  };

  gemmaE4b = "unsloth/gemma-4-E4B-it-GGUF:Q6_K_XL";
in {
  localModules.containers.services.litellm = {
    enable = true;
    models = [
      (mkLlamaCppModel "qwen3.6-35b-a3b" "unsloth/Qwen3.6-35B-A3B-GGUF:Q4_K_M")
      (mkLlamaCppModel "qwen3.6-27b" "unsloth/Qwen3.6-27B-GGUF:Q4_K_XL")
      (mkLlamaCppModel "gemma-4-e4b" gemmaE4b)
      {
        model_name = "ha-assist";
        litellm_params = {
          model = "openai/${gemmaE4b}";
          api_base = llamaCppApiBase;
          api_key = "none";
          # Disable the reasoning trace for Assist: it adds latency and can
          # consume the whole token budget, leaving content empty.
          extra_body.chat_template_kwargs.enable_thinking = false;
        };
      }
      {
        model_name = "whisper";
        litellm_params = {
          model = "openai/Systran/faster-whisper-medium";
          api_base = speachesApiBase;
          api_key = "none";
        };
        model_info.mode = "audio_transcription";
      }
      {
        model_name = "kokoro";
        litellm_params = {
          # fp16 ONNX is ~20% faster than fp32 on CPU (int8 is slower here).
          model = "openai/speaches-ai/Kokoro-82M-v1.0-ONNX-fp16";
          api_base = speachesApiBase;
          api_key = "none";
        };
      }
    ];
  };
}
