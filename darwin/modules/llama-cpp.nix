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
in {
  options.localModules.llamaCpp = {
    enable = lib.mkEnableOption "llama-cpp llama-server";

    package = lib.mkPackageOption pkgs ["unstable" "llama-cpp"] {};

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
      serviceConfig = {
        Label = "org.nixos.llama-cpp";
        ProgramArguments =
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
