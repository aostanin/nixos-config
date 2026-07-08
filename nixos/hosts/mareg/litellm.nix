{secrets, ...}: let
  llamaCppApiBase = "https://llama-cpp.${secrets.domain}/v1";

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
      (mkLlamaCppModel "ha-assist" gemmaE4b)
    ];
  };
}
