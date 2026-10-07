{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.localModules.whisper-cpp;
in {
  options.localModules.whisper-cpp = {
    enable = lib.mkEnableOption "whisper-cpp";

    package = lib.mkPackageOption pkgs "whisper-cpp" {};

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "large-v3-turbo-q5_0";
      description = "ggml model name, as accepted by download-ggml-model.sh.";
    };

    language = lib.mkOption {
      type = lib.types.str;
      default = "auto";
    };

    threads = lib.mkOption {
      type = lib.types.int;
      default = 8;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.whisper-cpp = {
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        DynamicUser = true;
        StateDirectory = "whisper-cpp";
        WorkingDirectory = "%S/whisper-cpp";
        CacheDirectory = "whisper-cpp";
        Restart = "on-failure";
      };
      # The packaged download script saves into the working directory.
      script = ''
        test -f ggml-${cfg.model}.bin \
          || ${lib.getExe' cfg.package "whisper-cpp-download-ggml-model"} ${cfg.model}
        # --inference-path is what makes /inference OpenAI-shaped.
        # --no-timestamps keeps each 30s window one segment; otherwise the text
        # is newline-split at clauses, and at 60 chars when token timestamps
        # are on.
        exec ${lib.getExe' cfg.package "whisper-server"} \
          -m ggml-${cfg.model}.bin \
          --no-timestamps \
          --host ${cfg.host} --port ${toString cfg.port} \
          --inference-path /v1/audio/transcriptions \
          -l ${cfg.language} -t ${toString cfg.threads} \
          --convert --tmp-dir "$CACHE_DIRECTORY"
      '';
    };
  };
}
