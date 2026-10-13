{
  config,
  pkgs,
  secrets,
  ...
}: let
  cfg = config.localModules.strata;
  dataDir = "/storage/appdata/temp/strata/data";
in {
  localModules.strata = {
    enable = true;
    package = pkgs.pkgsForCudaArch.sm_120.strata;
    cpuArch = "raptorlake";

    # Tuned for IQ3_XXS with setup.py --calibrate.
    settings = {
      args = [
        "--pack"
        "${dataDir}/packs/iq3_xxs"
        "--native"
        "${dataDir}/models/IQ3_XXS/Qwen3.8-Flash-Next-GSQ-RCO-IQ3_XXS-00001-of-00002.gguf"
        "--ple-gguf"
        "${dataDir}/models/IQ3_XXS/Qwen3.8-Flash-Next-GSQ-RCO-IQ3_XXS-00002-of-00002.gguf"
        "--expert-profile"
        "${cfg.finalPackage}/share/strata/data/expert-profile.bin"
        "--expert-cache"
        "auto"
        "--prefill"
        "auto"
        "--spec"
        "4"
        "--mtp"
        "${dataDir}/mtp/rt"
        "--max-context"
        "262144"
        "--kv"
        "int8"
        "--kv-resident"
        "20480"
        "--pcie-frac"
        "0.35"
        "--spec-min-p"
        "0.70"
        # Strata can't tell elena's P- and E-cores apart (every CPU reports the
        # same capacity), so --pool-affinity is a no-op. 7 workers plus the
        # host thread land on the P-cores. With 15, Kokoro's latency went from
        # 2 s to 28 s during decode.
        "--pool-workers"
        "7"
      ];
      tokenizer = "${dataDir}/packs/iq3_xxs/tokenizer";
      model_name = "qwen3.8-flash-next-iq3_xxs";
      gpu = 0;
      gpus_asked = true;
      host = "127.0.0.1";
      fit_max_tokens = true;
      draft_vocab = "en";
      # llama-swap passes the client's Host header through, and Strata rejects
      # unknown names as DNS rebinding.
      allowed_hosts = ["llama-cpp.${secrets.domain}"];
    };
  };

  services.llama-swap.settings = {
    # Strata's own engine start timeout; a cold start takes 3-5 minutes.
    healthCheckTimeout = 900;

    models.strata = {
      cmd = "${cfg.launcher} \${PORT}";
      unloadTimeout = 40;
      proxy = "http://127.0.0.1:\${PORT}";
      # Nothing listens until the model is loaded.
      checkEndpoint = "/health";
      # Keeps streaming clients from idling out during the load.
      sendLoadingState = true;
    };

    # Strata needs the whole GPU, and won't fit beside whisper.
    routing.router.settings.groups.strata = {
      exclusive = true;
      members = ["strata"];
    };
  };
}
