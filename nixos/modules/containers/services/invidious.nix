{
  lib,
  pkgs,
  config,
  secrets,
  ...
}: let
  name = "invidious";
  cfg = config.localModules.containers.services.${name};
  src = pkgs.fetchFromGitHub {
    owner = "iv-org";
    repo = "invidious";
    rev = "v2.20240427";
    sha256 = "sha256-P4Tz7spHfAopRmbw27x+7UAn2d9o7QWzBdFXYsnwIoQ=";
  };
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "containers/invidious/postgres_password" = {};
      "containers/invidious/hmac_key" = {};
    };

    sops.templates."${name}-config.yml" = {
      content = ''
        db:
          dbname: invidious
          user: invidious
          password: ${config.sops.placeholder."containers/invidious/postgres_password"}
          host: invidious-db
          port: 5432
        check_tables: true
        external_port: 443
        domain: ${lib.head (config.lib.containers.mkHosts name)}
        https_only: true
        # statistics_enabled: false
        hmac_key: ${config.sops.placeholder."containers/invidious/hmac_key"}
        registration_enabled: false
      '';
      # TODO: Want to set this to 1000, but sops requires a username.
      # ref: https://github.com/Mic92/sops-nix/issues/514
      owner = secrets.user.username;
    };

    sops.templates."${name}-db.env".content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder."containers/invidious/postgres_password"}
    '';

    localModules.containers.containers.${name} = {
      raw.image = "quay.io/invidious/invidious:latest";
      networks = [name];
      raw.dependsOn = ["${name}-db"];
      raw.volumes = [
        "${config.sops.templates."${name}-config.yml".path}:/invidious/config/config.yml"
      ];
      proxy = {
        enable = true;
        port = 3000;
      };
    };

    localModules.containers.containers."${name}-db" = {
      raw.image = "docker.io/library/postgres:14";
      networks = [name];
      raw.environment = {
        POSTGRES_USER = "invidious";
        POSTGRES_DB = "invidious";
      };
      raw.environmentFiles = [config.sops.templates."${name}-db.env".path];
      volumes.db = {
        parent = name;
        destination = "/var/lib/postgresql/data";
      };
      raw.volumes = [
        "${src}/config/sql:/config/sql"
        "${src}/docker/init-invidious-db.sh:/docker-entrypoint-initdb.d/init-invidious-db.sh"
      ];
      raw.extraOptions = [
        "--health-cmd"
        "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"
        "--health-start-period=30s"
      ];
    };
  };
}
