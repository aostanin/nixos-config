{
  pkgs,
  lib,
  inputs,
  ...
}: {
  services.llama-cpp = {
    enable = true;
    package = (pkgs.pkgsForCudaArch.sm_75.extend inputs.llama-cpp-turboquant.overlays.default).llama-cpp.overrideAttrs (old: {
      cmakeFlags =
        (old.cmakeFlags or [])
        ++ [
          (lib.cmakeBool "GGML_SSE42" true)
          (lib.cmakeBool "GGML_AVX" true)
          (lib.cmakeBool "GGML_AVX2" true)
          (lib.cmakeBool "GGML_FMA" true)
          (lib.cmakeBool "GGML_F16C" true)
          (lib.cmakeBool "GGML_AVX_VNNI" true)
        ];
    });
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
        mlock = "true";
        mmproj-offload = "false";
        flash-attn = "on";
        batch-size = "1024";
        ubatch-size = "512";
        threads = "8";
        threads-batch = "16";
        cpu-mask = "0xFFFF";
        cpu-strict = "1";
        parallel = "1";
        cont-batching = "true";
        timeout = "300";
        metrics = "true";
      };

      "unsloth/Qwen3.6-35B-A3B-GGUF:Q4_K_M" = {
        hf-repo = "unsloth/Qwen3.6-35B-A3B-GGUF";
        hf-file = "Qwen3.6-35B-A3B-UD-Q4_K_M.gguf";
        cache-type-k = "q8_0";
        cache-type-v = "turbo4";
        ctx-size = "131072";
        n-gpu-layers = "999";
        n-cpu-moe = "33";
        temp = "0.6";
        top-p = "0.95";
        top-k = "20";
      };

      "unsloth/Qwen3.6-27B-GGUF:Q4_K_M" = {
        hf-repo = "unsloth/Qwen3.6-27B-GGUF";
        hf-file = "Qwen3.6-27B-Q4_K_M.gguf";
        cache-type-k = "q8_0";
        cache-type-v = "turbo4";
        ctx-size = "131072";
        n-gpu-layers = "18";
        temp = "0.6";
        top-p = "0.95";
        top-k = "20";
      };

      "unsloth/Qwen3.5-9B-GGUF:Q4_K_XL" = {
        hf-repo = "unsloth/Qwen3.5-9B-GGUF";
        hf-file = "Qwen3.5-9B-UD-Q4_K_XL.gguf";
        cache-type-k = "turbo4";
        cache-type-v = "turbo4";
        ctx-size = "131072";
        n-gpu-layers = "999";
        temp = "0.6";
        top-p = "0.95";
        top-k = "20";
      };

      "unsloth/gemma-4-26B-A4B-it-GGUF:Q4_K_XL" = {
        hf-repo = "unsloth/gemma-4-26B-A4B-it-GGUF";
        hf-file = "gemma-4-26B-A4B-it-UD-Q4_K_XL.gguf";
        cache-type-k = "turbo4";
        cache-type-v = "turbo4";
        ctx-size = "131072";
        n-gpu-layers = "999";
        n-cpu-moe = "23";
        temp = "1.0";
        top-p = "0.95";
        top-k = "64";
      };

      "unsloth/gemma-4-E4B-it-GGUF:Q6_K_XL" = {
        hf-repo = "unsloth/gemma-4-E4B-it-GGUF";
        hf-file = "gemma-4-E4B-it-UD-Q6_K_XL.gguf";
        cache-type-k = "turbo4";
        cache-type-v = "turbo4";
        ctx-size = "131072";
        n-gpu-layers = "999";
        mmproj-offload = "true";
        temp = "1.0";
        top-p = "0.95";
        top-k = "64";
      };
    };
  };
}
