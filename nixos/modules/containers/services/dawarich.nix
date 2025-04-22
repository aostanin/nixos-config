{
  lib,
  config,
  ...
}: let
  name = "dawarich";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    enablePhoton = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.services.photon.enable = lib.mkDefault cfg.enablePhoton;

    sops.secrets = {
      "containers/${name}/postgres_password" = {};
    };

    sops.templates."${name}.env".content = let
      inherit (config.localModules.containers) domain;
    in ''
      APPLICATION_HOST=${name}.${domain}
      APPLICATION_HOSTS=${name}.${domain}
      DATABASE_HOST=${name}-db
      DATABASE_USERNAME=postgres
      DATABASE_PASSWORD=${config.sops.placeholder."containers/${name}/postgres_password"}
      DATABASE_NAME=${name}
      DATABASE_PORT=5432
      REDIS_URL=redis://${name}-redis:6379/1
      ${lib.optionalString cfg.enablePhoton "PHOTON_API_HOST=photon.${domain}"}
      DISTANCE_UNIT=km
      DISABLE_TELEMETRY=true
    '';

    sops.templates."${name}-db.env".content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder."containers/${name}/postgres_password"}
    '';

    localModules.containers.containers.${name} = {
      raw.image = "docker.io/freikin/dawarich:latest";
      networks = [name];
      raw.dependsOn = ["${name}-db" "${name}-redis"];
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      raw.entrypoint = "dev-entrypoint.sh";
      raw.cmd = ["bin/dev"];
      volumes = {
        gem_cache_app = {
          destination = "/usr/local/bundle/gems";
          storageType = "temp";
        };
        public.destination = "/var/app/public";
        watched.destination = "/var/app/tmp/imports/watched";
      };
      proxy = {
        enable = true;
        port = 3000;
      };
    };

    localModules.containers.containers."${name}-sidekiq" = {
      raw.image = "docker.io/freikin/dawarich:latest";
      networks = [name];
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      raw.entrypoint = "dev-entrypoint.sh";
      raw.cmd = ["sidekiq"];
      volumes = {
        gem_cache_app = {
          parent = name;
          destination = "/usr/local/bundle/gems";
          storageType = "temp";
        };
        public = {
          parent = name;
          destination = "/var/app/public";
        };
        watched = {
          parent = name;
          destination = "/var/app/tmp/imports/watched";
        };
      };
    };

    localModules.containers.containers."${name}-redis" = {
      raw.image = "docker.io/redis:7.0-alpine";
      networks = [name];
      volumes.shared = {
        parent = name;
        destination = "/var/shared/redis";
      };
    };

    localModules.containers.containers."${name}-db" = {
      raw.image = "docker.io/postgres:14.2-alpine";
      networks = [name];
      raw.environment = {
        POSTGRES_USER = "postgres";
        POSTGRES_DB = name;
      };
      raw.environmentFiles = [config.sops.templates."${name}-db.env".path];
      volumes = {
        db = {
          parent = name;
          destination = "/var/lib/postgresql/data";
        };
        shared = {
          parent = name;
          destination = "/var/shared";
        };
      };
    };
  };
}
