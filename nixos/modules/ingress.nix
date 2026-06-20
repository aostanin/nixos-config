{
  config,
  lib,
  localLib,
  ...
}: let
  cfg = config.localModules.ingress;
  domain = config.localModules.traefik.domain;
  hostName = config.networking.hostName;

  inherit (localLib) trustedClientIps mkHosts;

  accessSubmodule = enableByDefault:
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

  ingressSubmodule = lib.types.submodule ({
    name,
    config,
    ...
  }: {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Expose this service (DNS + routing).";
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = hostName;
        description = "Host that serves this entry (DNS target for bare names).";
      };

      hosts = lib.mkOption {
        type = with lib.types; listOf str;
        default = mkHosts {
          inherit domain name;
          host = config.host;
        };
        description = ''
          FQDNs this entry answers for (Traefik routing and DNS). The bare
          `<name>.${domain}` forms become DNS records; `.lan`/`.ts` forms are
          served by CoreDNS wildcards. Drop the bare form (or set to `[]`) to
          avoid exposing a name, e.g. for a secondary instance.
        '';
      };

      port = lib.mkOption {
        type = with lib.types; nullOr int;
        default = null;
        description = "Backend port (ignored when backendUrl is set).";
      };

      scheme = lib.mkOption {
        type = lib.types.enum ["http" "https"];
        default = "http";
        description = "Backend scheme (ignored when backendUrl is set).";
      };

      backendUrl = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = "Explicit backend URL, overriding scheme/port.";
      };

      trusted = lib.mkOption {
        type = accessSubmodule true;
        default = {};
        description = "Settings for traffic from trusted networks.";
      };

      default = lib.mkOption {
        type = accessSubmodule false;
        default = {};
        description = "Settings for traffic from all networks.";
      };

      container = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        internal = true;
        description = ''
          Set by the container module when this entry is backed by a container
          (routed via Traefik labels). Native entries leave this null and are
          routed via the file provider on their host.
        '';
      };
    };
  });
in {
  options.localModules.ingress = lib.mkOption {
    type = lib.types.attrsOf ingressSubmodule;
    default = {};
    description = "Exposed services (container or native).";
  };

  config = lib.mkIf config.localModules.traefik.enable {
    services.traefik.dynamicConfigOptions.http = let
      nativeEntries =
        lib.filterAttrs (n: e: e.enable && e.container == null && e.hosts != []) cfg;

      authMiddlewares = auth:
        if auth == "authelia"
        then ["authelia@file"]
        else if auth == "basic"
        then ["auth@file"]
        else [];

      mkEntry = name: e: let
        hostRules = lib.concatStringsSep " || " (map (h: "Host(`${h}`)") e.hosts);
        trustedClientRules = lib.concatStringsSep " || " (map (ip: "ClientIP(`${ip}`)") trustedClientIps);
        backend =
          if e.backendUrl != null
          then e.backendUrl
          else "${e.scheme}://127.0.0.1:${toString e.port}";
      in {
        routers =
          lib.optionalAttrs e.trusted.enable {
            "${name}-trusted" = {
              rule = "(${trustedClientRules}) && (${hostRules})";
              priority = 10;
              entrypoints = "websecure";
              service = name;
              middlewares = authMiddlewares e.trusted.auth;
            };
          }
          // lib.optionalAttrs e.default.enable {
            "${name}-default" = {
              rule = hostRules;
              priority = 5;
              entrypoints = "websecure";
              service = name;
              middlewares = authMiddlewares e.default.auth;
            };
          };
        services.${name}.loadbalancer.servers = [{url = backend;}];
      };

      entries = lib.mapAttrsToList mkEntry nativeEntries;
    in {
      routers = lib.mkMerge (map (e: e.routers) entries);
      services = lib.mkMerge (map (e: e.services) entries);
    };

    assertions =
      lib.mapAttrsToList (n: e: {
        assertion = !(e.enable && e.container == null && e.hosts != [] && (e.trusted.enable || e.default.enable) && e.port == null && e.backendUrl == null);
        message = "localModules.ingress.${n}: a routed native entry needs either `port` or `backendUrl`.";
      })
      cfg;
  };
}
