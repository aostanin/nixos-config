{
  config,
  pkgs,
  ...
}: {
  services.llama-cpp = {
    enable = true;
    package = pkgs.unstable.pkgsForCudaArch.sm_75.llama-cpp;
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

  localModules.ingress.llama-cpp.port = config.services.llama-cpp.port;

  # load-mode mmap+mlock locks multi-GB model buffers; default 8M rlimit is too low.
  systemd.services.llama-cpp = {
    serviceConfig.LimitMEMLOCK = "infinity";
  };
}
