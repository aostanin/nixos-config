{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.localModules.kokoro-fastapi;
in {
  options.localModules.kokoro-fastapi = {
    enable = lib.mkEnableOption "kokoro-fastapi";

    package = lib.mkPackageOption pkgs "kokoro-fastapi" {};

    enableNvidia = lib.mkEnableOption "CUDA; needs a CUDA package such as pkgs.pkgsForCudaArch.<arch>.kokoro-fastapi";

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8880;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.kokoro-fastapi = {
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      environment = {
        DEVICE_TYPE =
          if cfg.enableNvidia
          then "cuda"
          else "cpu";
        TEMP_FILE_DIR = "%C/kokoro-fastapi";
      };
      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package} --host ${cfg.host} --port ${toString cfg.port}";
        DynamicUser = true;
        CacheDirectory = "kokoro-fastapi";
        # Settings also load from a .env in the working directory.
        WorkingDirectory = "%C/kokoro-fastapi";
        Restart = "on-failure";
      };
    };
  };
}
