{
  lib,
  config,
  ...
}: let
  name = "lnbits";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/lnbits/lnbits:latest";
      raw.environment = {
        LNBITS_ADMIN_UI = "true";
        LNBITS_EXTENSIONS_PATH = "/app/data/extensions";
      };
      volumes.data.destination = "/app/data";
      proxy = {
        enable = true;
        port = 5000;
        default.enable = true;
      };
    };
  };
}
