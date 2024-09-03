{
  lib,
  config,
  ...
}: let
  cfg = config.localModules.containers.containers;

  mkHosts = name: let
    host = config.localModules.containers.host;
    domain = config.localModules.containers.domain;
  in [
    "${name}.${domain}"
    "${name}.${host}.lan.${domain}"
    "${name}.${host}.ts.${domain}"
  ];

  trustedClientIps = [
    "100.64.0.0/10" # TailScale
    "10.89.0.0/16" # Podman networks
    "10.0.0.0/24" # LAN
  ];

  mkProxyTypeSubmodule = enableByDefault:
    lib.types.submodule {
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = enableByDefault;
          description = "Enable access.";
        };

        auth = lib.mkOption {
          type = with lib.types; nullOr (enum ["authelia" "basic"]);
          default = null;
          description = "Authentication required to access.";
        };
      };
    };

  mkProxySubmodule = proxyName:
    lib.types.submodule (args @ {name, ...}: {
      options = {
        enable = lib.mkEnableOption "proxy";

        names = lib.mkOption {
          type = with lib.types; listOf str;
          default = [
            (
              if proxyName != null
              then proxyName
              else name
            )
          ];
          description = "Short names from which the host names will be derived.";
        };

        hosts = lib.mkOption {
          type = with lib.types; listOf str;
          default = lib.flatten (map (n: mkHosts n) args.config.names);
          description = "Hosts under which this service is available.";
        };

        port = lib.mkOption {
          type = with lib.types; nullOr int;
          default = null;
          description = "Port";
        };

        scheme = lib.mkOption {
          type = lib.types.enum ["http" "https"];
          default = "http";
          description = "Scheme.";
        };

        trusted = lib.mkOption {
          type = mkProxyTypeSubmodule true;
          default = {};
          description = "Settings for traffic from trusted networks.";
        };

        default = lib.mkOption {
          type = mkProxyTypeSubmodule false;
          default = {};
          description = "Settings for traffic from all networks.";
        };
      };
    });

  mkVolumesSubmodule = containerName:
    lib.types.submodule (args @ {name, ...}: {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "The name of the volume.";
        };

        source = lib.mkOption {
          type = lib.types.str;
          default = "${config.localModules.containers.storage.${args.config.storageType}}/${args.config.parent}/${args.config.name}";
          description = "The source of the mount.";
        };

        destination = lib.mkOption {
          type = lib.types.str;
          description = "The path where the directory is mounted in the container.";
        };

        parent = lib.mkOption {
          type = lib.types.str;
          default = containerName;
          description = "Parent directory. Defaults to the container name.";
        };

        storageType = lib.mkOption {
          type = lib.types.enum ["default" "bulk" "temp"];
          default = "default";
          description = ''
            The type of storage to use for this volume.

            `default` is for configuration files and other relatively small files.

            `bulk` is for large media files.

            `temp` is for temporary files.
          '';
        };

        user = lib.mkOption {
          type = lib.types.str;
          default = "root";
          description = "The user who owns this volume.";
        };

        group = lib.mkOption {
          type = lib.types.str;
          default = "root";
          description = "The group that owns this volume.";
        };

        mode = lib.mkOption {
          type = lib.types.str;
          default = "0755";
          description = "The mode for the volume.";
        };
      };
    });

  containerModule =
    lib.types.submodule
    (args @ {name, ...}: {
      options = {
        autoupdate = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Update the container with podman auto-update.";
        };

        proxy = lib.mkOption {
          type = mkProxySubmodule name;
          default = {};
          description = "Proxy settings";
        };

        proxies = lib.mkOption {
          type = lib.types.attrsOf (mkProxySubmodule null);
          default = {${name} = args.config.proxy;};
          description = "Multiple proxy settings";
        };

        networks = lib.mkOption {
          type = with lib.types; listOf str;
          default = [];
          description = "Container networks.";
        };

        volumes = lib.mkOption {
          type = lib.types.attrsOf (mkVolumesSubmodule name);
          default = {};
          description = "Container volumes.";
        };

        raw = lib.mkOption {
          type = with lib.types; attrsOf anything;
          default = {};
          description = "Configuration passed through to `virtualisation.oci-containers.<name>`.";
        };
      };
    });
in {
  options.localModules.containers.containers = lib.mkOption {
    type = lib.types.attrsOf containerModule;
    default = {};
    description = "Container definitions.";
  };

  config = let
    mkNetworks = opts:
      opts.networks
      ++ lib.optional (
        (lib.filter (p: p.enable) (lib.attrValues opts.proxies)) != []
      ) "proxy";
  in
    lib.mkIf config.localModules.containers.enable {
      lib.containers = {
        inherit mkHosts trustedClientIps;
      };

      localModules.containers.networks =
        lib.listToAttrs (map (n: lib.nameValuePair n {})
          (lib.flatten (lib.mapAttrsToList (n: v: mkNetworks v) cfg)));

      virtualisation.oci-containers.containers =
        lib.mapAttrs (
          name: opts:
            lib.mkMerge ([
                {
                  environment = {
                    TZ = lib.mkDefault config.time.timeZone;
                  };
                  volumes =
                    lib.mapAttrsToList (
                      n: v: "${v.source}:${v.destination}"
                    )
                    opts.volumes;
                  labels = lib.optionalAttrs opts.autoupdate {"io.containers.autoupdate" = "registry";};
                  extraOptions = map (n: "--network=${n}") (mkNetworks opts);
                }
              ]
              ++ (lib.mapAttrsToList (name: proxy: let
                  hostRules = lib.concatStringsSep " || " (map (host: "Host(`${host}`)") proxy.hosts);
                  trustedClientRules = lib.concatStringsSep " || " (map (host: "ClientIP(`${host}`)") trustedClientIps);
                  authMiddleware = auth:
                    lib.mkIf (auth != null) (
                      if auth == "authelia"
                      then "authelia@file"
                      else if auth == "basic"
                      then "auth@file"
                      else ""
                    );
                in {
                  labels =
                    {
                      "traefik.enable" = "true";
                      "traefik.http.services.${name}.loadbalancer.server.port" = lib.mkIf (proxy.port != null) (toString proxy.port);
                      "traefik.http.services.${name}.loadbalancer.server.scheme" = proxy.scheme;
                    }
                    // lib.optionalAttrs proxy.trusted.enable {
                      "traefik.http.routers.${name}-trusted.rule" = "(${trustedClientRules}) && (${hostRules})";
                      "traefik.http.routers.${name}-trusted.priority" = "10";
                      "traefik.http.routers.${name}-trusted.entrypoints" = "websecure";
                      "traefik.http.routers.${name}-trusted.service" = name;
                      "traefik.http.routers.${name}-trusted.middlewares" = authMiddleware proxy.trusted.auth;
                    }
                    // lib.optionalAttrs proxy.default.enable {
                      "traefik.http.routers.${name}-default.rule" = hostRules;
                      "traefik.http.routers.${name}-default.priority" = "5";
                      "traefik.http.routers.${name}-default.entrypoints" = "websecure";
                      "traefik.http.routers.${name}-default.service" = name;
                      "traefik.http.routers.${name}-default.middlewares" = authMiddleware proxy.default.auth;
                    };
                })
                (lib.filterAttrs (n: v: v.enable) opts.proxies))
              ++ [opts.raw])
        )
        cfg;

      systemd.services = lib.mapAttrs' (name: opts:
        lib.nameValuePair "podman-${name}" {
          after = map (n: "podman-${n}-network.service") (mkNetworks opts);
          requires = map (n: "podman-${n}-network.service") (mkNetworks opts);
        })
      cfg;

      systemd.tmpfiles.rules = lib.flatten (lib.mapAttrsToList (name: opts:
        lib.mapAttrsToList (n: v: "d '${v.source}' ${v.mode} ${v.user} ${v.group} - -") opts.volumes)
      cfg);
    };
}
