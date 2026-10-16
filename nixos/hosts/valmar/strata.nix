{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.localModules.strata;
  dataDir = "/persist/cache/strata/data";
  polyDir = "/persist/cache/polystrata";
  mayaDir = "/persist/cache/maya/models";

  # llama-swap passes the client's Host header through, and both engines reject
  # unknown names as DNS rebinding.
  allowedHosts = ["valmar" ".ts.net"];

  polystrata = pkgs.pkgsForCudaArch.sm_120.polystrata.override {cpuArch = "raptorlake";};

  polyLauncher = name: settings: let
    runConfig = pkgs.writeText "polystrata-${name}.json" (builtins.toJSON ({
        exe = "${polystrata}/share/polystrata/engine/strata-poly";
        cwd = "/var/lib/polystrata";
        log = "/var/lib/polystrata/${name}.log";
        host = "127.0.0.1";
        gpu = 0;
        fit_max_tokens = true;
        open_browser = false;
        allowed_hosts = allowedHosts;
      }
      // settings));
  in
    # The web UI's Settings view rewrites the config it was started with.
    pkgs.writeShellScript "polystrata-${name}-launch" ''
      install -D -m 644 ${runConfig} /run/polystrata/${name}.json
      exec ${polystrata}/bin/polystrata-server --engine strata --config /run/polystrata/${name}.json --port "$1"
    '';

  maya = pkgs.pkgsForCudaArch.sm_120.maya.override {cpuArch = "raptorlake";};

  mayaLauncher = name: settings: let
    runConfig = pkgs.writeText "maya-${name}.json" (builtins.toJSON ({
        exe = "${maya}/share/maya/engine/strata";
        cwd = "/var/lib/maya";
        log = "/var/lib/maya/${name}.log";
        host = "127.0.0.1";
        gpu = [0];
        model_name = "glm-5.3-flash";
        sampling = {
          temperature = 1.0;
          top_p = 0.95;
        };
        reasoning_effort = "high";
        fit_max_tokens = true;
      }
      // settings));
  in
    # The web UI's Settings view rewrites the config it was started with, and
    # the server writes the vision encoder's measured footprint beside it.
    pkgs.writeShellScript "maya-${name}-launch" ''
      install -D -m 644 ${runConfig} /run/maya/${name}.json
      exec ${maya}/bin/maya-server --engine strata --config /run/maya/${name}.json --port "$1"
    '';

  # No unloadTimeout: the engine stays loaded until another group needs the GPU.
  engineModel = cmd: {
    cmd = "${cmd} \${PORT}";
    proxy = "http://127.0.0.1:\${PORT}";
    # Nothing listens until the model is loaded.
    checkEndpoint = "/health";
    # Keeps streaming clients from idling out during a cold start.
    sendLoadingState = true;
  };
in {
  localModules.strata = {
    enable = true;
    package = pkgs.pkgsForCudaArch.sm_120.strata;
    cpuArch = "raptorlake";

    # setup.py's IQ3_S config; --spec-min-p 0.70 measured faster here.
    settings = {
      args = [
        "--pack"
        "${dataDir}/packs/iq3_s"
        "--native"
        "${dataDir}/models/IQ3_S/Qwen3.8-Flash-Next-GSQ-RCO-IQ3_S-00001-of-00002.gguf"
        "--ple-gguf"
        "${dataDir}/models/IQ3_S/Qwen3.8-Flash-Next-GSQ-RCO-IQ3_S-00002-of-00002.gguf"
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
        "32768"
        "--spec-min-p"
        "0.70"
      ];
      tokenizer = "${dataDir}/packs/iq3_s/tokenizer";
      model_name = "qwen3.8-flash-next-iq3_s";
      gpu = 0;
      gpus_asked = true;
      host = "127.0.0.1";
      fit_max_tokens = true;
      draft_vocab = "en";
      allowed_hosts = allowedHosts;

      # The encoder starts with the first picture, in VRAM the expert cache
      # gives up, and stops after two idle minutes.
      vram_elastic = true;
      vision = {
        exe = "${cfg.finalPackage}/share/strata/engine/strata-vision";
        mmproj = "${dataDir}/models/mmproj-Qwen3.8-Flash-Next-BF16.gguf";
        # Opened for its vocabulary only.
        model = "${dataDir}/models/IQ3_S/Qwen3.8-Flash-Next-GSQ-RCO-IQ3_S-00001-of-00002.gguf";
        gpu = true;
        max_tokens = 1024;
        elastic = true;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/polystrata 0750 root root -"
    "d /var/lib/maya 0750 root root -"
  ];

  services.llama-swap.settings = {
    # The engines' own start timeout; a Strata cold start takes minutes.
    healthCheckTimeout = 900;

    models = {
      strata = engineModel cfg.launcher;

      polystrata-ornith = engineModel (polyLauncher "ornith" {
        args = [
          "--model"
          "${polyDir}/Ornith-1.5-35B-Q4_K_M.gguf"
          "--max-context"
          "131072"
          "--expert-profile"
          "${polyDir}/ornith/expert-profile.txt"
          # The default checkpoints miss a new request that shares a long
          # system prompt.
          "--prompt-cache-every"
          "512"
          "--prompt-cache"
          "8"
        ];
        tokenizer = "${polyDir}/ornith/tokenizer";
        model_name = "ornith-1.5-35b-a3b";
      });

      polystrata-gemma = engineModel (polyLauncher "gemma" {
        args = [
          "--model"
          "${polyDir}/gemma/gemma-4-26B-A4B-it-UD-Q4_K_M.gguf"
          "--max-context"
          "131072"
          "--expert-profile"
          "${polyDir}/gemma/expert-profile-Q4_K_M.txt"
          "--draft-model"
          "${polyDir}/gemma/mtp-gemma-4-26B-A4B-it-Q8_0.gguf"
          "--prompt-cache-every"
          "512"
          "--prompt-cache"
          "8"
        ];
        tokenizer = "${polyDir}/gemma/tokenizer";
        model_name = "gemma-4-26b-a4b";
      });

      maya-glm = engineModel (mayaLauncher "glm" {
        args = [
          "--glm-pack"
          "${mayaDir}/Maya-S24/pack"
          "--max-context"
          "131072"
          "--expert-cache"
          "auto"
          "--prefill"
          "auto"
          "--kv-streaming"
          "on"
          "--expert-profile"
          "${maya}/share/maya/data/expert-profile-glm.bin"
        ];
        tokenizer = "${mayaDir}/Maya-S24/pack/tokenizer";
        vision = {
          exe = "${maya}/share/maya/engine/strata-vision";
          mmproj = "${mayaDir}/vision/mmproj-GLM-5.3-Flash-F16.gguf";
          # Opened for its vocabulary only.
          model = "${mayaDir}/vision/GLM-5.3-Flash-vocab.gguf";
          gpu = true;
        };
      });
    };

    # Each engine fills the VRAM, so only one runs at a time.
    routing.router.settings.groups = lib.genAttrs ["strata" "polystrata-ornith" "polystrata-gemma" "maya-glm"] (name: {
      exclusive = true;
      members = [name];
    });
  };
}
