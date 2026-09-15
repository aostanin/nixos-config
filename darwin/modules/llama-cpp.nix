{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.localModules.llamaCpp;

  stateDir = "/var/lib/llama-cpp";
  cacheDir = "/var/cache/llama-cpp";
  logDir = "/var/log/llama-cpp";

  modelsPresetFile =
    if cfg.modelsPreset != null
    then pkgs.writeText "llama-models.ini" (lib.generators.toINI {} cfg.modelsPreset)
    else null;

  serverArgs =
    [
      "${cfg.package}/bin/llama-server"
      "--host"
      cfg.host
      "--port"
      (toString cfg.port)
    ]
    ++ lib.optionals (cfg.model != null) ["-m" (toString cfg.model)]
    ++ lib.optionals (cfg.modelsDir != null) ["--models-dir" (toString cfg.modelsDir)]
    ++ lib.optionals (cfg.modelsPreset != null) ["--models-preset" "${modelsPresetFile}"]
    ++ cfg.extraFlags;

  # Read HF_TOKEN from a file at launch: a launchd EnvironmentVariables entry
  # would bake the secret into the world-readable plist in the store.
  launchScript = pkgs.writeShellScript "llama-server-launch" ''
    ${lib.optionalString (cfg.hfTokenFile != null) ''
      if [ -r ${lib.escapeShellArg cfg.hfTokenFile} ]; then
        export HF_TOKEN="$(${pkgs.coreutils}/bin/cat ${lib.escapeShellArg cfg.hfTokenFile})"
      fi
    ''}
    exec ${lib.escapeShellArgs serverArgs}
  '';
in {
  options.localModules.llamaCpp = {
    enable = lib.mkEnableOption "llama-cpp llama-server";

    package = lib.mkPackageOption pkgs ["llama-cpp"] {};

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      example = "0.0.0.0";
      description = "Address llama-server listens on.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port llama-server listens on.";
    };

    model = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/models/mistral-instruct-7b/ggml-model-q4_0.gguf";
      description = "Path to a single model file.";
    };

    modelsDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/models";
      description = "Directory containing model files.";
    };

    modelsPreset = lib.mkOption {
      type = lib.types.nullOr (lib.types.attrsOf lib.types.attrs);
      default = null;
      description = ''
        Preset configuration as a Nix attribute set, converted to an INI file
        and passed to llama-server via --models-preset.
      '';
    };

    hfTokenFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/run/secrets/huggingface/token";
      description = "File whose contents are exported as HF_TOKEN, for pulling gated HuggingFace models.";
    };

    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["-c" "4096" "-ngl" "32"];
      description = "Extra flags passed to llama-server.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [cfg.package];

    system.activationScripts.preActivation.text = ''
      mkdir -p ${stateDir} ${cacheDir} ${logDir}
    '';

    launchd.daemons.llama-cpp = {
      command = "${launchScript}";

      serviceConfig = {
        Label = "org.nixos.llama-cpp";
        EnvironmentVariables = {
          LLAMA_CACHE = cacheDir;
        };
        WorkingDirectory = stateDir;
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "${logDir}/llama-cpp.log";
        StandardErrorPath = "${logDir}/llama-cpp.log";
      };
    };
  };
}
