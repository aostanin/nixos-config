{
  lib,
  config,
  ...
}: let
  name = "endurain";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "containers/${name}/secret_key" = {};
      "containers/${name}/fernet_key" = {};
      "containers/${name}/postgres_password" = {};
    };

    sops.templates."${name}.env".content = ''
      DB_PASSWORD=${config.sops.placeholder."containers/${name}/postgres_password"}
      SECRET_KEY=${config.sops.placeholder."containers/${name}/secret_key"}
      FERNET_KEY=${config.sops.placeholder."containers/${name}/fernet_key"}
    '';

    sops.templates."${name}-db.env".content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder."containers/${name}/postgres_password"}
    '';

    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/endurain-project/endurain:latest";
      networks = [name];
      raw.dependsOn = ["${name}-db"];
      raw.environment = {
        ENDURAIN_HOST = "https://${name}.${config.localModules.containers.domain}";
        BEHIND_PROXY = "true";
        # Host Traefik connects via the podman network gateway.
        TRUSTED_PROXIES = "10.88.0.0/15";
        DB_HOST = "${name}-db";
      };
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      # Same as the image's built-in check; an explicit cmd makes the deploy wait
      # for healthy instead of racing the first probe.
      healthcheck = {
        cmd = "curl -f http://localhost:8080/api/v1/about";
        interval = "10s";
        startPeriod = "2m";
      };
      # The image runs as UID 1000.
      volumes = {
        data = {
          destination = "/app/backend/data";
          user = "1000";
        };
        logs = {
          destination = "/app/backend/logs";
          storageType = "temp";
          user = "1000";
        };
      };
      proxy = {
        enable = true;
        port = 8080;
      };
    };

    localModules.containers.containers."${name}-db" = {
      raw.image = "docker.io/library/postgres:18";
      networks = [name];
      raw.environment = {
        POSTGRES_USER = name;
        POSTGRES_DB = name;
        PGDATA = "/var/lib/postgresql/data/pgdata";
      };
      raw.environmentFiles = [config.sops.templates."${name}-db.env".path];
      volumes.db = {
        parent = name;
        destination = "/var/lib/postgresql/data";
      };
      healthcheck = {
        cmd = "pg_isready -U ${name} -d ${name}";
        interval = "10s";
        startPeriod = "30s";
      };
    };
  };
}
