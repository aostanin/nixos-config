{
  config,
  lib,
  options,
  pkgs,
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
    sops.secrets = {
      "traefik/basic_auth_users".owner = "traefik";
      "traefik/cloudflare/email" = {};
      "traefik/cloudflare/api_token" = {};
    };

    sops.templates."traefik.env".content = ''
      CF_API_EMAIL=${config.sops.placeholder."traefik/cloudflare/email"}
      CF_DNS_API_TOKEN=${config.sops.placeholder."traefik/cloudflare/api_token"}
    '';

    systemd.services.traefik = {
      after = ["podman-proxy-network.service"];
      requires = ["podman-proxy-network.service"];
    };

    services.traefik = {
      enable = true;
      group =
        if config.virtualisation.docker.enable
        then "docker"
        else if config.virtualisation.podman.enable
        then "podman"
        else options.services.traefik.group;
      environmentFiles = [config.sops.templates."traefik.env".path];
      staticConfigOptions = let
        host = config.networking.hostName;
        domain = cfg.domain;
      in {
        global = {
          checkNewVersion = false;
          sendAnonymousUsage = false;
        };
        log.level = "INFO";
        providers.docker = {
          endpoint =
            if config.virtualisation.podman.enable
            then "unix:///run/podman/podman.sock"
            else "unix:///run/docker.sock";
          network = lib.mkDefault "proxy";
          exposedByDefault = false;
        };
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
      dynamicConfigOptions = {
        http.middlewares.auth.basicAuth.usersFile = config.sops.secrets."traefik/basic_auth_users".path;

        http.middlewares.authelia.forwardAuth = {
          # TODO: Dynamically find the host running authelia
          address = "http://${secrets.network.tailscale.hosts.roan.address}:9091/api/authz/forward-auth";
          authResponseHeaders = "Remote-User,Remote-Groups,Remote-Email,Remote-Name";
          trustForwardHeader = "true";
        };
      };
    };
  };
}
