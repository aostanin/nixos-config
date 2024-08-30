{
  lib,
  config,
  ...
}: let
  name = "searxng";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/searxng/searxng:latest";
      volumes.data.destination = "/etc/searxng";
      proxy = {
        enable = true;
        names = ["searx"];
        default.enable = true;
        default.auth = "authelia";
      };
    };
  };
}
