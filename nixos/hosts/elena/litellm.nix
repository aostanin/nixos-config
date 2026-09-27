{
  config,
  lib,
  secrets,
  ...
}: let
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

  # One litellm entry per mymcp endpoint: each is its own MCP server, and
  # keeping them separate is what lets a client mount only what it needs.
  mkMymcp = eps:
    lib.listToAttrs (map (ep:
      lib.nameValuePair "my_${ep}" {
        url = "https://mymcp.${secrets.domain}/${ep}/mcp";
        transport = "http";
        auth_type = "bearer_token";
        authentication_token = config.sops.placeholder."containers/mymcp/bearer_token";
      })
    eps);
in {
  # Declared here rather than in the module: which MCP servers litellm fronts is
  # a host decision.
  sops.secrets = {
    "containers/litellm/ha_mcp_token" = {};
    "containers/mymcp/bearer_token" = {};
  };

  localModules.containers.services.litellm = {
    enable = true;

    # Underscores, not hyphens: litellm rejects '-' in an mcp server name, and
    # the name becomes the prefix on every tool it exposes.
    # Ported from ~/Sync/notes/.maki/mcp.toml. domi is deliberately absent: its
    # 41 tools cost ~28.6k tokens, 61% of that prose descriptions, which every
    # client would re-prefill every turn. nextcloud is absent too — it only ran
    # over stdio there, which needs a uv runtime litellm's image lacks.
    mcpServers =
      {
        home_assistant = {
          url = "https://home.${secrets.domain}/api/mcp";
          transport = "http";
          auth_type = "bearer_token";
          authentication_token = config.sops.placeholder."containers/litellm/ha_mcp_token";
        };
      }
      // mkMymcp ["calendar" "matrix" "feeds" "search" "reddit" "rides" "grist"];

    models = [
      (mkLlamaCppModel "ornith-1.5-35b-a3b" "ornith-ai/Ornith-1.5-35B-A3B-GGUF:Q4_K_M")
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
