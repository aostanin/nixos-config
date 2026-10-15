{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.llama-swap;
  llamaCpp = config.services.llama-cpp;

  llamaCppCmd = lib.concatStringsSep " " ([
      "${llamaCpp.package}/bin/llama-server"
      "--host 127.0.0.1 --port \${PORT}"
      "--models-preset ${pkgs.writeText "llama-models.ini" (lib.generators.toINI {} llamaCpp.modelsPreset)}"
    ]
    ++ llamaCpp.extraFlags);
in {
  services.llama-swap = {
    enable = true;
    package = pkgs.unstable.llama-swap;
    listenAddress = "0.0.0.0";
    port = 8085;
    settings = {
      logToStdout = "both";

      models = {
        # The router swaps between its own models (--models-max 1); llama-swap
        # only sees one process and routes every preset name to it.
        llamacpp = {
          cmd = llamaCppCmd;
          proxy = "http://127.0.0.1:\${PORT}";
          aliases = lib.attrNames (removeAttrs llamaCpp.modelsPreset ["*"]);
        };
      };

      routing.router.settings.groups = {
        gpu = {
          swap = false;
          exclusive = true;
          members = ["llamacpp"];
        };
      };
    };
  };

  # Root, unsandboxed: the router mlocks model buffers, and the engines read
  # their models from /persist/cache.
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

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [cfg.port];
}
