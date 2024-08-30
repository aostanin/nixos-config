{
  lib,
  config,
  ...
}: let
  name = "guacamole";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "containers/guacamole/postgres_password" = {};
    };

    sops.templates."${name}-db.env".content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder."containers/guacamole/postgres_password"}
    '';

    localModules.containers.containers.${name} = {
      raw.image = "docker.io/guacamole/guacamole:latest";
      networks = [name];
      raw.dependsOn = ["${name}-db" "${name}-guacd"];
      raw.environment = {
        GUACD_HOSTNAME = "host.containers.internal";
        GUACD_PORT = "4822";
        POSTGRES_HOSTNAME = "${name}-db";
        POSTGRES_PORT = "5432";
        POSTGRES_DATABASE = "guacamole_db";
        POSTGRES_USER = "postgres";
      };
      raw.environmentFiles = [config.sops.templates."${name}-db.env".path];
      proxy = {
        enable = true;
        port = 8080;
      };
      raw.labels = {
        "traefik.http.routers.${name}-trusted.middlewares" = "add-guacamole";
        "traefik.http.middlewares.add-guacamole.addprefix.prefix" = "/guacamole";
      };
    };

    localModules.containers.containers."${name}-guacd" = {
      raw.image = "docker.io/guacamole/guacd:latest";
      raw.environmentFiles = [config.sops.templates."${name}-db.env".path];
      raw.extraOptions = ["--network=host"];
    };

    localModules.containers.containers."${name}-db" = {
      raw.image = "docker.io/library/postgres:11-alpine";
      networks = [name];
      raw.environment = {
        POSTGRES_USER = "postgres";
        POSTGRES_DB = "guacamole_db";
      };
      raw.environmentFiles = [config.sops.templates."${name}-db.env".path];
      volumes.db = {
        parent = name;
        destination = "/var/lib/postgresql/data";
      };
    };
  };
}
