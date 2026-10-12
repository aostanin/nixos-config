{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.llama-swap;
  llamaCpp = config.services.llama-cpp;
  whisper = config.localModules.whisper-cpp;

  # The services' own state, left under private/ by their DynamicUser units.
  llamaCppCache = "/var/cache/private/llama-cpp";
  whisperState = "/var/lib/private/whisper-cpp";

  llamaCppCmd = lib.concatStringsSep " " ([
      "${llamaCpp.package}/bin/llama-server"
      "--host 127.0.0.1 --port \${PORT}"
      "--models-preset ${pkgs.writeText "llama-models.ini" (lib.generators.toINI {} llamaCpp.modelsPreset)}"
    ]
    ++ llamaCpp.extraFlags);

  whisperLaunch = pkgs.writeShellScript "whisper-launch" ''
    cd ${whisperState}
    test -f ggml-${whisper.model}.bin \
      || ${lib.getExe' whisper.package "whisper-cpp-download-ggml-model"} ${whisper.model}
    # Same flags as the standalone service; see modules/whisper-cpp.nix.
    exec ${lib.getExe' whisper.package "whisper-server"} \
      -m ggml-${whisper.model}.bin \
      --no-timestamps \
      --host 127.0.0.1 --port "$1" \
      --inference-path /v1/audio/transcriptions \
      -l ${whisper.language} -t ${toString whisper.threads} \
      --convert --tmp-dir /var/cache/private/whisper-cpp
  '';
in {
  services.llama-swap = {
    enable = true;
    package = pkgs.unstable.llama-swap;
    listenAddress = "127.0.0.1";
    port = 8085;
    settings = {
      logToStdout = "both";
      hooks.on_startup.preload = ["llamacpp" "whisper"];

      models = {
        # The router swaps between its own models (--models-max 1); llama-swap
        # only sees one process and routes every preset name to it.
        llamacpp = {
          cmd = llamaCppCmd;
          proxy = "http://127.0.0.1:\${PORT}";
          env = ["LLAMA_CACHE=${llamaCppCache}"];
          aliases = lib.attrNames (removeAttrs llamaCpp.modelsPreset ["*"]);
        };

        whisper = {
          cmd = "${whisperLaunch} \${PORT}";
          proxy = "http://127.0.0.1:\${PORT}";
          # What OpenAI clients put in the multipart model field.
          aliases = ["whisper-1"];
        };
      };

      routing.router.settings.groups.gpu = {
        swap = false;
        exclusive = true;
        members = ["llamacpp" "whisper"];
      };
    };
  };

  # Root, unsandboxed: the router mlocks model buffers and reads the state of
  # the disabled services above.
  systemd.services.llama-swap = {
    serviceConfig =
      {
        LimitMEMLOCK = "infinity";
      }
      // lib.mapAttrs (_: lib.mkForce) {
        DynamicUser = false;
        PrivateUsers = false;
        CapabilityBoundingSet = [];
        NoNewPrivileges = false;
        RestrictAddressFamilies = [];
        RestrictNamespaces = false;
        RestrictSUIDSGID = false;
        SystemCallFilter = [];
        SystemCallArchitectures = [];
        MemoryDenyWriteExecute = false;
        LockPersonality = false;
        PrivateMounts = false;
        PrivateTmp = false;
        ProtectSystem = false;
        ProtectHome = false;
        ProtectProc = "default";
        ProtectControlGroups = false;
        ProtectKernelModules = false;
        ProtectKernelTunables = false;
        ProtectKernelLogs = false;
        ProtectClock = false;
        ProtectHostname = false;
        RemoveIPC = false;
        RestrictRealtime = false;
      };
  };

  # Hostnames kept from the standalone services, which llama-swap replaces.
  localModules.ingress.llama-cpp.port = cfg.port;
  localModules.ingress.whisper-cpp.port = cfg.port;
}
