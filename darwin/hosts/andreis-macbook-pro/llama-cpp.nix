{pkgs, ...}: {
  localModules.llamaCpp = {
    enable = true;
    # nixpkgs-unstable (9842+) for MTP support + newer Metal kernels; 26.05 is 9190.
    package = pkgs.unstable.llama-cpp;
    host = "0.0.0.0";
    port = 8085;
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
        mlock = "true";
        threads = "10";
        threads-batch = "10";
        sleep-idle-seconds = "300";
        parallel = "1";
        cont-batching = "true";
        timeout = "300";
        metrics = "true";
      };

      "unsloth/Qwen3.6-35B-A3B-GGUF:Q4_K_M" = {
        hf-repo = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF";
        hf-file = "Qwen3.6-35B-A3B-UD-Q4_K_M.gguf";
        ctx-size = "262144";
        spec-type = "draft-mtp";
        spec-draft-n-max = "2";
        temp = "0.6";
        top-p = "0.95";
        top-k = "20";
      };

      "unsloth/Qwen3.6-27B-GGUF:Q5_K_XL" = {
        hf-repo = "unsloth/Qwen3.6-27B-GGUF";
        hf-file = "Qwen3.6-27B-UD-Q5_K_XL.gguf";
        ctx-size = "262144";
        temp = "0.6";
        top-p = "0.95";
        top-k = "20";
      };

      "unsloth/gemma-4-E4B-it-GGUF:Q6_K_XL" = {
        hf-repo = "unsloth/gemma-4-E4B-it-GGUF";
        hf-file = "gemma-4-E4B-it-UD-Q6_K_XL.gguf";
        ctx-size = "262144";
        temp = "1.0";
        top-p = "0.95";
        top-k = "64";
      };
    };
  };
}
