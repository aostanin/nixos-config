{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: let
  splash = pkgs.splash.override {python3 = pkgs.unstable.python313;};
  whisper-cpp = pkgs.unstable.whisper-cpp;
  whisperModel = "large-v3-turbo-q5_0";

  qwen38-27b = "ajgazin/Swift-Qwen3.8-27B-Uncensored-Dynamic-MTP-GGUF:UD-Q5_K_M";
  qwen36-35b = "ornith-ai/Ornith-1.5-35B-A3B-GGUF:Q5_K_M";

  mkSplash = model: revision: {
    cmd = lib.concatStringsSep " " ([
        (lib.getExe splash)
        "serve"
        "--model"
        model
        "--revision"
        revision
        "--host"
        "127.0.0.1"
        "--port"
        "\${PORT}"
      ]
      # llama-swap passes the client's Host header through to the model.
      ++ lib.concatMap (host: ["--allowed-host" host]) [
        config.networking.hostName
        "${config.networking.hostName}.local"
        secrets.network.tailscale.hosts.andreis-macbook-pro.address
      ]);
    proxy = "http://127.0.0.1:\${PORT}";
    # /health answers before the model has loaded.
    checkEndpoint = "/ready";
    # Models, agent sessions and prepared weights live under HOME/Library.
    env = [
      "HOME=/var/lib/splash"
      "HF_HUB_CACHE=/var/cache/splash"
    ];
    unloadTimeout = 30;
  };

  # The packaged download script saves into the working directory, and on
  # darwin whisper-server converts input with the ffmpeg on PATH.
  whisperLaunch = pkgs.writeShellScript "whisper-launch" ''
    export PATH=${lib.makeBinPath [pkgs.ffmpeg-headless]}:$PATH
    cd /var/lib/whisper-cpp
    test -f ggml-${whisperModel}.bin \
      || ${lib.getExe' whisper-cpp "whisper-cpp-download-ggml-model"} ${whisperModel}
    # --inference-path is what makes /inference OpenAI-shaped.
    # --no-timestamps keeps each 30s window one segment.
    exec ${lib.getExe' whisper-cpp "whisper-server"} \
      -m ggml-${whisperModel}.bin \
      --no-timestamps \
      --host 127.0.0.1 --port "$1" \
      --inference-path /v1/audio/transcriptions \
      -l auto \
      --convert --tmp-dir /var/cache/whisper-cpp
  '';
in {
  sops.secrets."splash/api_key" = {};

  system.activationScripts.preActivation.text = ''
    mkdir -p /var/lib/splash /var/cache/splash /var/lib/whisper-cpp /var/cache/whisper-cpp /var/cache/kokoro
  '';

  localModules.llamaSwap = {
    enable = true;
    package = pkgs.unstable.llama-swap;
    host = "0.0.0.0";
    port = 8085;
    apiKeyFile = config.sops.secrets."splash/api_key".path;
    wakeOnRequest = true;
    settings = {
      healthCheckTimeout = 600;
      logToStdout = "both";
      hooks.on_startup.preload = [qwen38-27b];

      models = {
        ${qwen38-27b} = mkSplash qwen38-27b "6a7d8701f966d221cf076b4a4240d875a0ced02d";
        ${qwen36-35b} = mkSplash qwen36-35b "12393612fd4f730ff5aadc23e9b8f9648aa49ceb";

        whisper = {
          cmd = "${whisperLaunch} \${PORT}";
          proxy = "http://127.0.0.1:\${PORT}";
          ttl = 300;
        };

        kokoro = {
          cmd = "${lib.getExe pkgs.kokoro-fastapi} --host 127.0.0.1 --port \${PORT}";
          proxy = "http://127.0.0.1:\${PORT}";
          # It would pick MPS, which is far slower than the CPU for Kokoro.
          env = [
            "DEVICE_TYPE=cpu"
            "TEMP_FILE_DIR=/var/cache/kokoro"
          ];
          ttl = 300;
        };
      };

      routing.router.settings.groups = {
        # Both chat models won't fit in memory at once.
        chat = {
          swap = true;
          exclusive = false;
          members = [qwen38-27b qwen36-35b];
        };
        audio = {
          swap = false;
          exclusive = false;
          members = ["whisper" "kokoro"];
        };
      };
    };
  };
}
