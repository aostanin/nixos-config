{
  lib,
  config,
  ...
}: let
  name = "nginx";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/library/nginx:alpine";
      volumes.html.destination = "/usr/share/nginx/html:ro";
      proxy = {
        enable = true;
        hosts = [config.localModules.containers.domain];
        port = 80;
        default.enable = true;
      };
    };
  };
}
