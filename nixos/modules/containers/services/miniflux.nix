{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "miniflux";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption name {};
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
      "containers/miniflux/admin_username" = {};
      "containers/miniflux/admin_password" = {};
      "containers/miniflux/postgres_password" = {};
    };

    sops.templates."${name}.env".content = ''
      DATABASE_URL=postgres://miniflux:${config.sops.placeholder."containers/miniflux/postgres_password"}@${name}-db/miniflux?sslmode=disable
      ADMIN_USERNAME=${config.sops.placeholder."containers/miniflux/admin_username"}
      ADMIN_PASSWORD=${config.sops.placeholder."containers/miniflux/admin_password"}
    '';

    sops.templates."${name}-db.env".content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder."containers/miniflux/postgres_password"}
    '';

    localModules.containers.networks.${name} = {};

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "docker.io/miniflux/miniflux:latest";
        dependsOn = ["${name}-db"];
        environment = {
          "RUN_MIGRATIONS" = "1";
          "CREATE_ADMIN" = "1";
        };
        environmentFiles = [config.sops.templates."${name}.env".path];
        extraOptions = [
          "--network=${name}"
          "--health-cmd"
          "/usr/bin/miniflux -healthcheck auto"
        ];
      }
      mkContainerDefaultConfig
      (mkContainerProxyConfig name cfg.proxy)
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    virtualisation.oci-containers.containers."${name}-db" = lib.mkMerge [
      {
        image = "docker.io/postgres:15";
        environment = {
          POSTGRES_USER = "miniflux";
          POSTGRES_DB = "miniflux";
        };
        environmentFiles = [config.sops.templates."${name}-db.env".path];
        volumes = ["${cfg.volumes.db.path}:/var/lib/postgresql/data"];
        extraOptions = [
          "--network=${name}"
          "--health-cmd"
          "pg_isready -U miniflux"
          "--health-interval=10s"
          "--health-start-period=30s"
        ];
      }
      mkContainerDefaultConfig
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.services."podman-${name}" = mkServiceProxyConfig name cfg.proxy;

    systemd.tmpfiles.rules = mkTmpfileVolumesConfig cfg.volumes;
  };
}
