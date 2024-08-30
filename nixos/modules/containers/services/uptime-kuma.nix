{
  lib,
  config,
  ...
}: let
  name = "uptime-kuma";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/louislam/uptime-kuma:1";
      volumes.data.destination = "/app/data";
      proxy = {
        enable = true;
        names = ["uptime"];
      };
    };
  };
}
