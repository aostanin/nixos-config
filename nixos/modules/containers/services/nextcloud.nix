{
  lib,
  pkgs,
  config,
  localLib,
  ...
}: let
  name = "nextcloud";
  cfg = config.localModules.containers.services.${name};
  domain = config.localModules.containers.domain;
  host = config.localModules.containers.host;
  hosts = localLib.mkHosts {inherit domain host name;};

  # Runs once after first install; installs the CalDAV/CardDAV apps as the web
  # user. Needs an executable file with an in-container shebang.
  installApps = pkgs.writeTextFile {
    name = "nextcloud-install-apps.sh";
    executable = true;
    # Best-effort: a transient appstore/DNS failure must not abort container start.
    text = ''
      #!/bin/sh
      for app in calendar contacts tasks; do
        su -p www-data -s /bin/sh -c "php /var/www/html/occ app:install $app" || true
      done
      exit 0
    '';
  };
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "containers/${name}/admin_password" = {};
      "containers/${name}/postgres_password" = {};
    };

    sops.templates."${name}.env".content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder."containers/${name}/postgres_password"}
      NEXTCLOUD_ADMIN_PASSWORD=${config.sops.placeholder."containers/${name}/admin_password"}
    '';

    sops.templates."${name}-db.env".content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder."containers/${name}/postgres_password"}
    '';

    localModules.containers.containers.${name} = {
      raw.image = "docker.io/nextcloud:33-apache";
      networks = [name];
      raw.dependsOn = ["${name}-db" "${name}-redis"];
      raw.environment = {
        POSTGRES_HOST = "${name}-db";
        POSTGRES_DB = name;
        POSTGRES_USER = name;
        REDIS_HOST = "${name}-redis";
        NEXTCLOUD_ADMIN_USER = "admin";
        NEXTCLOUD_TRUSTED_DOMAINS = lib.concatStringsSep " " hosts;
        TRUSTED_PROXIES = "10.0.0.0/8 172.16.0.0/12 192.168.0.0/16";
        OVERWRITEPROTOCOL = "https";
        OVERWRITECLIURL = "https://${lib.head hosts}";
        PHP_UPLOAD_LIMIT = "10G";
      };
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      raw.volumes = ["${installApps}:/docker-entrypoint-hooks.d/post-installation/install-apps.sh:ro"];
      raw.labels = {
        # Nextcloud's Apache emits http:// for .well-known/{cal,card}dav behind a
        # TLS-terminating proxy; redirect these at Traefik instead (docs-recommended).
        "traefik.http.middlewares.${name}-wellknown.redirectregex.permanent" = "true";
        "traefik.http.middlewares.${name}-wellknown.redirectregex.regex" = "https://(.*)/.well-known/(?:card|cal)dav";
        "traefik.http.middlewares.${name}-wellknown.redirectregex.replacement" = "https://\${1}/remote.php/dav";
        "traefik.http.routers.${name}-trusted.middlewares" = "${name}-wellknown";
      };
      volumes.html.destination = "/var/www/html";
      proxy = {
        enable = true;
        port = 80;
      };
    };

    localModules.containers.containers."${name}-redis" = {
      raw.image = "docker.io/redis:7-alpine";
      networks = [name];
      healthcheck = {
        cmd = "redis-cli ping";
        interval = "10s";
        startPeriod = "30s";
      };
    };

    localModules.containers.containers."${name}-db" = {
      raw.image = "docker.io/postgres:16-alpine";
      networks = [name];
      raw.environment = {
        POSTGRES_USER = name;
        POSTGRES_DB = name;
      };
      raw.environmentFiles = [config.sops.templates."${name}-db.env".path];
      healthcheck = {
        cmd = "pg_isready -U ${name}";
        interval = "10s";
        startPeriod = "30s";
      };
      volumes.db.destination = "/var/lib/postgresql/data";
    };
  };
}
