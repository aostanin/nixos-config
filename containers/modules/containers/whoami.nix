{
  lib,
  config,
  ...
}: let
  cfg = config.localModules.containers.containers.whoami;
in {
  options.localModules.containers.containers.whoami = {
    # TODO: lib
    enable = lib.mkEnableOption "whoami";
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.traefik.enable = true;

    services.podman.containers.whoami = {
      image = "docker.io/traefik/whoami";
      # TODO: lib
      networks = ["proxy"];
      autoupdate = "registry";

      # TODO: lib
      labels = let
        name = "whoami";
        hosts = let
          inherit (config.localModules.containers) host domain;
        in [
          "${name}.${domain}"
          "${name}.${host}.lan.${domain}"
          "${name}.${host}.ts.${domain}"
        ];
        hostRules = lib.concatStringsSep " || " (map (host: "Host(\\`${host}\\`)") hosts);
      in
        lib.mapAttrsToList (n: v: "'${n}=${toString v}'") {
          # TODO: lib
          "traefik.enable" = "true";
          "traefik.http.routers.${name}-ts.rule" = "ClientIP(\\`100.64.0.0/10\\`) && (${hostRules})";
          "traefik.http.routers.${name}-ts.priority" = "10";
          "traefik.http.routers.${name}-ts.entrypoints" = "websecure";
          "traefik.http.routers.${name}-ts.service" = name;

          "traefik.http.routers.${name}-default.rule" = hostRules;
          "traefik.http.routers.${name}-default.priority" = "5";
          "traefik.http.routers.${name}-default.entrypoints" = "websecure";
          "traefik.http.routers.${name}-default.service" = name;

          # TODO: middleware not found?
          # "traefik.http.routers.${name}-default.middlewares" = "auth";
          # "traefik.http.routers.${name}-default.middlewares" = "authelia";
        };
    };
  };
}
