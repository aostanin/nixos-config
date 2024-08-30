{
  lib,
  config,
  ...
}: let
  name = "whoami";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/traefik/whoami:latest";
      proxy = {
        enable = true;
        default.enable = true;
        default.auth = "authelia";
      };
    };
  };
}
