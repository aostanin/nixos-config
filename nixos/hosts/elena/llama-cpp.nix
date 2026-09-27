{
  pkgs,
  lib,
  ...
}: {
  services.llama-cpp = {
    enable = true;
    package = pkgs.unstable.pkgsForCudaArch.sm_75.llama-cpp.overrideAttrs (old: {
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
    host = "127.0.0.1";
    port = 8085;
    extraFlags = [
      "--models-max"
      "1"
      "--webui-mcp-proxy"
    ];
    modelsPreset = {
      "*" = {
        jinja = "true";
        load-mode = "mmap+mlock";
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

      "ornith-ai/Ornith-1.5-35B-A3B-GGUF:Q4_K_M" = {
        hf-repo = "ornith-ai/Ornith-1.5-35B-A3B-GGUF";
        hf-file = "Ornith-1.5-35B-Q4_K_M.gguf";
        cache-type-k = "q8_0";
        cache-type-v = "q8_0";
        ctx-size = "131072";
        n-gpu-layers = "999";
        n-cpu-moe = "37";
        batch-size = "2048";
        ubatch-size = "2048";
        load-mode = "auto";
        timeout = "1800";
        temp = "0.6";
        top-p = "0.95";
        top-k = "20";
      };

      "ornith-ai/Ornith-1.5-9B-GGUF:Q4_K_M" = {
        hf-repo = "ornith-ai/Ornith-1.5-9B-GGUF";
        hf-file = "Ornith-1.5-9B-Q4_K_M.gguf";
        load-on-startup = "true";
        cache-type-k = "q8_0";
        cache-type-v = "q8_0";
        ctx-size = "65536";
        n-gpu-layers = "999";
        temp = "0.6";
        top-p = "0.95";
        top-k = "20";
      };
    };
  };

  # load-mode mmap+mlock locks multi-GB model buffers; default 8M rlimit is too low.
  systemd.services.llama-cpp.serviceConfig.LimitMEMLOCK = "infinity";

  localModules.ingress.llama-cpp.port = 8085;
}
