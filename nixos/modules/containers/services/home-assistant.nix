{
  lib,
  config,
  ...
}: let
  name = "home-assistant";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/home-assistant/home-assistant:stable";
      volumes.config.destination = "/config";
      raw.volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "/run/dbus:/run/dbus:ro"
      ];
      raw.extraOptions = [
        "--privileged"
        "--network=host"
      ];
    };

    services.traefik.dynamicConfigOptions = let
      hostRules =
        lib.concatStringsSep " || " (map (host: "Host(`${host}`)")
          (config.lib.containers.mkHosts "home"));
    in {
      http.routers.home-assistant = {
        rule = hostRules;
        entrypoints = "websecure";
        service = name;
      };
      http.services.home-assistant.loadbalancer.servers = [
        {url = "http://127.0.0.1:8123";}
      ];
    };
  };
}
