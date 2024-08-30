{
  lib,
  config,
  ...
}: let
  name = "miniflux";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "containers/miniflux/admin_username" = {};
      "containers/miniflux/admin_password" = {};
      "containers/miniflux/postgres_password" = {};
    };

    sops.templates."${name}.env".content = ''
      DATABASE_URL=postgres://postgres:${config.sops.placeholder."containers/miniflux/postgres_password"}@${name}-db/miniflux?sslmode=disable
      ADMIN_USERNAME=${config.sops.placeholder."containers/miniflux/admin_username"}
      ADMIN_PASSWORD=${config.sops.placeholder."containers/miniflux/admin_password"}
    '';

    sops.templates."${name}-db.env".content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder."containers/miniflux/postgres_password"}
    '';

    localModules.containers.containers.${name} = {
      raw.image = "docker.io/miniflux/miniflux:latest";
      networks = [name];
      raw.dependsOn = ["${name}-db"];
      raw.environment = {
        "RUN_MIGRATIONS" = "1";
        "CREATE_ADMIN" = "1";
      };
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      raw.extraOptions = [
        "--health-cmd"
        "/usr/bin/miniflux -healthcheck auto"
        "--health-start-period=30s"
      ];
      proxy.enable = true;
    };

    localModules.containers.containers."${name}-db" = {
      raw.image = "docker.io/library/postgres:11-alpine";
      networks = [name];
      raw.environment = {
        POSTGRES_USER = "postgres";
        POSTGRES_DB = "miniflux";
      };
      raw.environmentFiles = [config.sops.templates."${name}-db.env".path];
      volumes.db = {
        parent = name;
        destination = "/var/lib/postgresql/data";
      };
      raw.extraOptions = [
        "--health-cmd"
        "pg_isready -U miniflux"
        "--health-interval=10s"
        "--health-start-period=30s"
      ];
    };
  };
}
