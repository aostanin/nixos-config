{
  pkgs,
  config,
  lib,
  options,
  secrets,
  ...
}: let
  cfg = config.localModules.traefik;
in {
  options.localModules.traefik = {
    enable = lib.mkEnableOption "traefik";

    domain = lib.mkOption {
      type = lib.types.str;
      default = secrets.domain;
      description = ''
        The domain name.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."traefik" = {};

    services.traefik = {
      enable = true;
      group =
        if config.virtualisation.docker.enable
        then "docker"
        else if config.virtualisation.podman.enable
        then "podman"
        else options.services.traefik.group;
      environmentFiles = [config.sops.secrets."traefik".path];
      staticConfigOptions = let
        host = config.networking.hostName;
        domain = cfg.domain;
      in {
        global = {
          checkNewVersion = false;
          sendAnonymousUsage = false;
        };
        log.level = "INFO";
        providers.docker.exposedByDefault = false;
        serversTransport.insecureSkipVerify = true;
        certificatesResolvers.default.acme = {
          email = "admin@${cfg.domain}";
          storage = "${config.services.traefik.dataDir}/acme.json";
          dnsChallenge = {
            provider = "cloudflare";
            resolvers = ["1.1.1.1:53" "8.8.8.8:53"];
          };
        };
        entryPoints = {
          web = {
            address = ":80";
            http.redirections.entrypoint = {
              to = "websecure";
              scheme = "https";
            };
          };
          websecure = {
            address = ":443";
            http.tls = {
              certResolver = "default";
              domains = [
                {
                  main = domain;
                  sans = [
                    "*.${domain}"
                    "${host}.lan.${domain}"
                    "*.${host}.lan.${domain}"
                    "${host}.ts.${domain}"
                    "*.${host}.ts.${domain}"
                  ];
                }
              ];
            };
          };
        };
      };
      # Using dynamicConfigOptions escapes the quotes needed for go templating
      dynamicConfigFile = pkgs.writeText "dynamic.toml" ''
        [http.middlewares.auth.basicAuth]
        users = "{{ env "BASIC_AUTH_USERS" }}"

        [http.middlewares.authelia.forwardAuth]
        address = "{{ env "AUTHELIA_FORWARD_AUTH_ADDRESS" }}"
        authResponseHeaders = "Remote-User,Remote-Groups,Remote-Email,Remote-Name"
        trustForwardHeader = "true"
      '';
    };
  };
}
