{
  config,
  pkgs,
  ...
}: {
  sops.secrets."huggingface/token" = {};

  localModules.llamaCpp = {
    enable = true;
    # nixpkgs-unstable for MTP support + newer Metal kernels; 26.05 lags well behind.
    package = pkgs.unstable.llama-cpp;
    host = "0.0.0.0";
    port = 8085;
    hfTokenFile = config.sops.secrets."huggingface/token".path;
    extraFlags = [
      "--models-max"
      "1"
      "--webui-mcp-proxy"
    ];
    modelsPreset = {
      "*" = {
        jinja = "true";
        n-gpu-layers = "999";
        cache-type-k = "q8_0";
        cache-type-v = "q8_0";
        flash-attn = "on";
        batch-size = "2048";
        ubatch-size = "2048";
        load-mode = "mmap+mlock";
        threads = "10";
        threads-batch = "10";
        sleep-idle-seconds = "300";
        parallel = "1";
        cont-batching = "true";
        timeout = "300";
        metrics = "true";
      };

      "unsloth/Qwen3.8-27B-GGUF:Q5_K_XL" = {
        hf-repo = "unsloth/Qwen3.8-27B-GGUF";
        hf-file = "Qwen3.8-27B-UD-Q5_K_XL.gguf";
        ctx-size = "262144";
        temp = "0.6";
        top-p = "0.95";
        top-k = "20";
      };

      "ornith-ai/Ornith-1.5-35B-A3B-GGUF:Q5_K_M" = {
        hf-repo = "ornith-ai/Ornith-1.5-35B-A3B-GGUF";
        hf-file = "Ornith-1.5-35B-Q5_K_M.gguf";
        ctx-size = "262144";
        # Embedded MTP measured a net loss at depth: 33.7 -> 28.2 tok/s at 57.6k fill.
        temp = "0.6";
        top-p = "0.95";
        top-k = "20";
      };

      "SAPSAN-SKLEP/HIDra-30B-A3B-GGUF:Q5_K_M" = {
        hf-repo = "SAPSAN-SKLEP/HIDra-30B-A3B-GGUF-uncensored-cybersec";
        hf-file = "HIDra-30B-A3B-Q5_K_M.gguf";
        ctx-size = "262144";
        temp = "0.7";
        top-p = "0.8";
        top-k = "20";
        repeat-penalty = "1.05";
      };

      "ajgazin/Swift-Qwen3.8-27B-Uncensored-Dynamic-MTP-GGUF:Q5_K_M" = {
        hf-repo = "ajgazin/Swift-Qwen3.8-27B-Uncensored-Dynamic-MTP-GGUF";
        hf-file = "Swift-Qwen3.8-27B-Uncensored-Dynamic-MTP-UD-Q5_K_M.gguf";
        ctx-size = "262144";
        temp = "0.6";
        top-p = "0.95";
        top-k = "20";
      };
    };
  };
}
