{
  lib,
  config,
  ...
}: let
  name = "immich";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    uploadLocation = lib.mkOption {
      type = lib.types.str;
      description = "Photo upload location";
    };

    devices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra devices to bind to the container.";
    };

    volumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra volumes to bind to the container.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "containers/${name}/postgres_password" = {};
    };

    sops.templates."${name}.env".content = ''
      DB_HOSTNAME=${name}-db
      DB_USERNAME=postgres
      DB_PASSWORD=${config.sops.placeholder."containers/${name}/postgres_password"}
      DB_DATABASE_NAME=${name}
      REDIS_HOSTNAME=${name}-redis
      LOG_LEVEL=log
      IMMICH_SERVER_URL=http://${name}-server:2283
      IMMICH_MACHINE_LEARNING_URL=http://${name}-machine-learning:3003
    '';

    sops.templates."${name}-db.env".content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder."containers/${name}/postgres_password"}
    '';

    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/immich-app/immich-server:release";
      networks = [name];
      raw.dependsOn = ["${name}-db" "${name}-redis"];
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      volumes = {
        upload = {
          parent = name;
          source = cfg.uploadLocation;
          destination = "/usr/src/app/upload";
          storageType = "temp";
        };
        thumbs = {
          parent = name;
          destination = "/usr/src/app/upload/thumbs";
          storageType = "bulk";
        };
      };
      raw.volumes = cfg.volumes;
      raw.extraOptions = lib.map (d: "--device=${d}") cfg.devices;
      proxy = {
        enable = true;
        port = 2283;
      };
    };

    localModules.containers.containers."${name}-machine-learning" = {
      raw.image = "ghcr.io/immich-app/immich-machine-learning:release";
      networks = [name];
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      volumes.cache = {
        parent = name;
        destination = "/cache";
        storageType = "temp";
      };
    };

    localModules.containers.containers."${name}-redis" = {
      raw.image = "docker.io/redis:6.2-alpine";
      networks = [name];
    };

    localModules.containers.containers."${name}-db" = {
      raw.image = "docker.io/tensorchord/pgvecto-rs:pg14-v0.2.0";
      networks = [name];
      raw.environment = {
        POSTGRES_USER = "postgres";
        POSTGRES_DB = name;
        POSTGRES_INITDB_ARGS = "--data-checksums";
      };
      raw.environmentFiles = [config.sops.templates."${name}-db.env".path];
      volumes.db = {
        parent = name;
        destination = "/var/lib/postgresql/data";
      };
      raw.cmd = ["postgres" "-c" "shared_preload_libraries=vectors.so" "-c" "search_path=\"$$user\", public, vectors" "-c" "logging_collector=on" "-c" "max_wal_size=2GB" "-c" "shared_buffers=512MB" "-c" "wal_compression=on"];
    };
  };
}
