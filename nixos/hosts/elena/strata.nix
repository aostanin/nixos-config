{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: let
  version = "0.1.40.4";
  image = "localhost/strata:${version}";
  # Upstream rewrites history, so pin the tag's commit rather than the tag.
  src = pkgs.fetchFromGitHub {
    owner = "Niko1221";
    repo = "Strata";
    rev = "6674a0065fb96bacde33e3eb10f91a1df86f95f2";
    hash = "sha256-F9e6Uq92DA9L1WTTrfPaVjQsNCLZACAQJ+g3CYYocmo=";
  };
  podman = lib.getExe config.virtualisation.podman.package;
  dataDir = "/storage/appdata/temp/strata/data";
  configPath = "/etc/strata/strata-iq3_xxs.json";

  # setup.py's output for IQ3_XXS, tuned with its --calibrate. Generated here
  # because the web UI's Settings view rewrites the config it was started
  # with, and once silently zeroed the VRAM reserve.
  runConfig = pkgs.writeText "strata-iq3_xxs.json" (builtins.toJSON {
    exe = "/opt/strata/engine/strata";
    args = [
      "--pack"
      "/data/packs/iq3_xxs"
      "--native"
      "/data/models/IQ3_XXS/Qwen3.8-Flash-Next-GSQ-RCO-IQ3_XXS-00001-of-00002.gguf"
      "--ple-gguf"
      "/data/models/IQ3_XXS/Qwen3.8-Flash-Next-GSQ-RCO-IQ3_XXS-00002-of-00002.gguf"
      "--expert-profile"
      "/opt/strata/data/expert-profile.bin"
      "--expert-cache"
      "auto"
      "--prefill"
      "auto"
      "--spec"
      "4"
      "--mtp"
      "/data/mtp/rt"
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
    cwd = "/opt/strata";
    tokenizer = "/data/packs/iq3_xxs/tokenizer";
    model_name = "qwen3.8-flash-next-iq3_xxs";
    log = "/opt/strata/strata-iq3_xxs.log";
    lib_dirs = ["/usr/local/cuda/bin" "/usr/local/cuda/lib64"];
    port = 8080;
    gpu = 0;
    gpus_asked = true;
    host = "0.0.0.0";
    fit_max_tokens = true;
    draft_vocab = "en";
    # llama-swap passes the client's Host header through, and Strata rejects
    # unknown names as DNS rebinding.
    allowed_hosts = ["llama-cpp.${secrets.domain}"];
  });

  # setup.py touches its config on start, so it can't be mounted read-only;
  # a fresh copy each start still discards edits made through the web UI.
  # MODEL is mandatory even with CONFIG: unset, the entry point defaults to
  # IQ2_XS and downloads it.
  launch = pkgs.writeShellScript "strata-launch" ''
    install -D -m 644 ${runConfig} /run/strata/strata-iq3_xxs.json
    exec ${podman} run --rm --replace --name strata --no-healthcheck \
      --device nvidia.com/gpu=all --ulimit memlock=-1:-1 \
      -v ${dataDir}:/data -v /run/strata/strata-iq3_xxs.json:${configPath} \
      -p 127.0.0.1:"$1":8080 \
      -e MODEL=IQ3_XXS -e VISION=no -e CONFIG=${configPath} \
      ${image}
  '';
in {
  # Builds only when the tagged image is missing.
  systemd.services.strata-image = {
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${podman} image exists ${image} \
        || ${podman} build --build-arg CUDA_ARCHITECTURES=75 --build-arg BUILD_VISION=0 -t ${image} ${src}
    '';
  };

  services.llama-swap.settings = {
    # Strata's own engine start timeout; a cold start takes 3-5 minutes.
    healthCheckTimeout = 900;

    models.strata = {
      cmd = "${launch} \${PORT}";
      cmdStop = "${podman} stop -t 30 strata";
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

  # podman detaches the container from the service's cgroup; don't leave it
  # holding the GPU if llama-swap dies.
  systemd.services.llama-swap.serviceConfig.ExecStopPost = "${podman} rm --force --ignore --time 30 strata";
}
