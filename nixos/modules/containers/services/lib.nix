{
  lib,
  config,
  ...
}: rec {
  mkDefaultHosts = name: {
    host ? config.localModules.containers.host,
    domain ? config.localModules.containers.domain,
  }: [
    "${name}.${domain}"
    "${name}.${host}.lan.${domain}"
    "${name}.${host}.ts.${domain}"
  ];

  mkAutoupdateOption = name: lib.mkEnableOption "autoupdate ${name}";

  mkVolumeOption = with lib.types;
    name: {
      storageType ? "default",
      volumeName ? "data",
      user ? "root",
      group ? "root",
      mode ? "0750",
    }:
      lib.mkOption {
        type = submodule {
          options = {
            path = lib.mkOption {
              type = str;
              default = "${config.localModules.containers.storage.${storageType}}/${name}/${volumeName}";
              description = ''
                ${volumeName} path.
              '';
            };

            user = lib.mkOption {
              type = str;
              default = user;
              description = ''
                ${volumeName} user.
              '';
            };

            group = lib.mkOption {
              type = str;
              default = group;
              description = ''
                ${volumeName} group.
              '';
            };

            mode = lib.mkOption {
              type = str;
              default = mode;
              description = ''
                ${volumeName} mode.
              '';
            };
          };
        };
        default = {};
        description = ''
          ${volumeName} volume.
        '';
      };

  mkVolumesOption = with lib.types;
    name: volumes:
      lib.mkOption {
        type = submodule {
          options =
            lib.mapAttrs (
              n: v: mkVolumeOption name v
            )
            volumes;
        };
        default = {};
        description = ''
          ${name} volumes.
        '';
      };

  mkProxyTypeOption = with lib.types;
    proxyType:
      lib.mkOption {
        type = submodule {
          options = {
            enable = lib.mkEnableOption "${proxyType} proxy";

            auth = lib.mkOption {
              type = nullOr (enum ["authelia" "basic"]);
              default = null;
              description = ''
                Authentication required to access.
              '';
            };
          };
        };
        default = {};
        description = ''
          Settings for ${proxyType} clients.
        '';
      };

  mkProxyOption = with lib.types;
    name: {
      scheme ? "http",
      port ? null,
      host ? config.localModules.containers.host,
      domain ? config.localModules.containers.domain,
    }:
      lib.mkOption {
        type = submodule {
          options = {
            enable = lib.mkEnableOption "proxy";

            hosts = lib.mkOption {
              type = listOf str;
              default = mkDefaultHosts name {
                inherit host domain;
              };
              description = ''
                Hosts under which this service is available.
              '';
            };

            port = lib.mkOption {
              type = nullOr int;
              default = port;
              description = ''
                Port.
              '';
            };

            scheme = lib.mkOption {
              type = enum ["http" "https"];
              default = scheme;
              description = ''
                Scheme.
              '';
            };

            tailscale = mkProxyTypeOption "TailScale";

            lan = mkProxyTypeOption "LAN";

            net = mkProxyTypeOption "Internet";
          };
        };
        default = {};
        description = ''
          Proxy settings.
        '';
      };

  mkContainerDefaultConfig = {
    environment = {
      TZ = config.time.timeZone;
    };
  };

  mkContainerProxyConfig = name: cfg:
    lib.mkIf cfg.enable {
      labels = let
        hostRules = lib.concatStringsSep " || " (map (host: "Host(`${host}`)") cfg.hosts);
        authMiddleware = auth:
          lib.mkIf (auth != null) (
            if auth == "authelia"
            then "authelia@file"
            else if auth == "basic"
            then "auth@file"
            else ""
          );
      in
        {
          "traefik.enable" = "true";
          "traefik.http.services.${name}.loadbalancer.server.port" = lib.mkIf (cfg.port != null) (toString cfg.port);
          "traefik.http.services.${name}.loadbalancer.server.scheme" = cfg.scheme;
        }
        // lib.optionalAttrs cfg.tailscale.enable {
          "traefik.http.routers.${name}-ts.rule" = "ClientIP(`100.64.0.0/10`) && (${hostRules})";
          "traefik.http.routers.${name}-ts.priority" = "15";
          "traefik.http.routers.${name}-ts.entrypoints" = "websecure";
          "traefik.http.routers.${name}-ts.service" = name;
          "traefik.http.routers.${name}-ts.middlewares" = authMiddleware cfg.tailscale.auth;
        }
        // lib.optionalAttrs cfg.lan.enable {
          "traefik.http.routers.${name}-lan.rule" = "ClientIP(`10.0.0.0/24`) && (${hostRules})";
          "traefik.http.routers.${name}-lan.priority" = "10";
          "traefik.http.routers.${name}-lan.entrypoints" = "websecure";
          "traefik.http.routers.${name}-lan.service" = name;
          "traefik.http.routers.${name}-lan.middlewares" = authMiddleware cfg.lan.auth;
        }
        // lib.optionalAttrs cfg.net.enable {
          "traefik.http.routers.${name}-default.rule" = hostRules;
          "traefik.http.routers.${name}-default.priority" = "5";
          "traefik.http.routers.${name}-default.entrypoints" = "websecure";
          "traefik.http.routers.${name}-default.service" = name;
          "traefik.http.routers.${name}-default.middlewares" = authMiddleware cfg.net.auth;
        };

      extraOptions = [
        "--network=proxy"
      ];
    };

  mkContainerAutoupdateConfig = name: cfg:
    lib.mkIf cfg {
      labels = {
        "io.containers.autoupdate" = "registry";
      };
    };

  mkServiceProxyConfig = name: cfg:
    lib.mkIf cfg.enable {
      after = ["podman-proxy-network.service"];
      requires = ["podman-proxy-network.service"];
    };

  mkTmpfileVolumesConfig = cfg: lib.mapAttrsToList (n: v: "d '${v.path}' ${v.mode} ${v.user} ${v.group} - -") cfg;
}
