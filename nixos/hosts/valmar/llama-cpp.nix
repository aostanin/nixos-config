{
  pkgs,
  lib,
  ...
}: {
  # Run by llama-swap (llama-swap.nix), which reads these settings.
  services.llama-cpp = {
    enable = false;
    package = pkgs.unstable.pkgsForCudaArch.sm_120.llama-cpp.overrideAttrs (old: {
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

      # The 35B runs on PolyStrata (strata.nix), which is faster with the same
      # GGUF.
      "ornith-ai/Ornith-1.5-9B-GGUF:Q4_K_M" = {
        model = "/persist/cache/polystrata/Ornith-1.5-9B-Q4_K_M.gguf";
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
}
