{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "guacamole";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption name {port = 8080;};
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
      };
    };

    sops.secrets = {
      "containers/guacamole/postgres_password" = {};
    };

    sops.templates."${name}-db.env".content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder."containers/guacamole/postgres_password"}
    '';

    localModules.containers.networks.${name} = {};

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "docker.io/guacamole/guacamole:latest";
        dependsOn = ["${name}-db" "${name}-guacd"];
        environment = {
          GUACD_HOSTNAME = "host.containers.internal";
          GUACD_PORT = "4822";
          POSTGRES_HOSTNAME = "${name}-db";
          POSTGRES_PORT = "5432";
          POSTGRES_DATABASE = "guacamole_db";
          POSTGRES_USER = "postgres";
        };
        environmentFiles = [config.sops.templates."${name}-db.env".path];
        extraOptions = ["--network=${name}"];
      }
      mkContainerDefaultConfig
      (mkContainerProxyConfig name cfg.proxy)
      (mkContainerAutoupdateConfig name cfg.autoupdate)
      {
        # TODO: Don't set Traefik labels here
        labels = {
          "traefik.http.routers.guacamole-ts.middlewares" = "add-guacamole";
          "traefik.http.middlewares.add-guacamole.addprefix.prefix" = "/guacamole";
        };
      }
    ];

    virtualisation.oci-containers.containers."${name}-guacd" = lib.mkMerge [
      {
        image = "docker.io/guacamole/guacd:latest";
        environmentFiles = [config.sops.templates."${name}-db.env".path];
        extraOptions = ["--network=host"];
      }
      mkContainerDefaultConfig
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    virtualisation.oci-containers.containers."${name}-db" = lib.mkMerge [
      {
        image = "docker.io/library/postgres:11-alpine";
        environment = {
          POSTGRES_USER = "postgres";
          POSTGRES_DB = "guacamole_db";
        };
        environmentFiles = [config.sops.templates."${name}-db.env".path];
        volumes = [
          "${cfg.volumes.db.path}:/var/lib/postgresql/data"
        ];
        extraOptions = ["--network=${name}"];
      }
      mkContainerDefaultConfig
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.services."podman-${name}" = lib.mkMerge [
      (mkServiceProxyConfig name cfg.proxy)
      (mkServiceNetworksConfig name [name])
    ];
    systemd.services."podman-${name}-guacd" = mkServiceNetworksConfig name [name];
    systemd.services."podman-${name}-db" = mkServiceNetworksConfig name [name];

    systemd.tmpfiles.rules = mkTmpfileVolumesConfig cfg.volumes;
  };
}
