{
  lib,
  pkgs,
  config,
  containerLib,
  secrets,
  ...
}:
with containerLib; let
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
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption name {port = 3000;};
    volumes = mkVolumesOption name {
      db = {};
    };
  };

  config = lib.mkIf (config.localModules.containers.enable && cfg.enable) {
    localModules.containers.services.${name} = {
      autoupdate = lib.mkDefault true;
      proxy = {
        enable = lib.mkDefault true;
        tailscale.enable = lib.mkDefault true;
        lan.enable = lib.mkDefault true;
      };
    };

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
        domain: ${lib.head cfg.proxy.hosts}
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

    localModules.containers.networks.${name} = {};

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "quay.io/invidious/invidious:latest";
        dependsOn = ["${name}-db"];
        volumes = [
          "${config.sops.templates."${name}-config.yml".path}:/invidious/config/config.yml"
        ];
        extraOptions = [
          "--network=${name}"
          "--health-cmd"
          "wget -nv --tries=1 --spider http://127.0.0.1:3000/api/v1/comments/jNQXAC9IVRw || exit 1"
          "--health-interval=30s"
          "--health-timeout=5s"
          "--health-retries=2"
        ];
      }
      mkContainerDefaultConfig
      (mkContainerProxyConfig name cfg.proxy)
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    virtualisation.oci-containers.containers."${name}-db" = lib.mkMerge [
      {
        image = "docker.io/library/postgres:14";
        environment = {
          POSTGRES_USER = "invidious";
          POSTGRES_DB = "invidious";
        };
        environmentFiles = [config.sops.templates."${name}-db.env".path];
        volumes = [
          "${cfg.volumes.db.path}:/var/lib/postgresql/data"
          "${src}/config/sql:/config/sql"

          "${src}/docker/init-invidious-db.sh:/docker-entrypoint-initdb.d/init-invidious-db.sh"
        ];
        extraOptions = [
          "--network=${name}"
          "--health-cmd"
          "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"
        ];
      }
      mkContainerDefaultConfig
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.services."podman-${name}" = lib.mkMerge [
      (mkServiceProxyConfig name cfg.proxy)
      (mkServiceNetworksConfig name [name])
    ];
    systemd.services."podman-${name}-db" = mkServiceNetworksConfig name [name];

    systemd.tmpfiles.rules = mkTmpfileVolumesConfig cfg.volumes;
  };
}
