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
      "traefik/authelia/forward_auth_address" = {};
      "traefik/basic_auth_users" = {};
      "traefik/cloudflare/email" = {};
      "traefik/cloudflare/api_token" = {};
    };

    sops.templates."traefik.env".content = ''
      CF_API_EMAIL=${config.sops.placeholder."traefik/cloudflare/email"}
      CF_DNS_API_TOKEN=${config.sops.placeholder."traefik/cloudflare/api_token"}
    '';

    sops.templates."traefik-dynamic.toml" = let
      zwift-offline = pkgs.fetchFromGitHub {
        owner = "zoffline";
        repo = "zwift-offline";
        rev = "zoffline_1.0.134206";
        sha256 = "sha256-B3kXIPWDIVcAzrqSR6HMtaSFMCAtRlCUyi1JvZdoyLQ=";
      };
    in {
      owner = "traefik";
      content = ''
        [http.middlewares.auth.basicAuth]
        users = "${config.sops.placeholder."traefik/basic_auth_users"}"

        [http.middlewares.authelia.forwardAuth]
        address = "${config.sops.placeholder."traefik/authelia/forward_auth_address"}"
        authResponseHeaders = "Remote-User,Remote-Groups,Remote-Email,Remote-Name"
        trustForwardHeader = "true"

        ${lib.optionalString config.localModules.containers.services.zwift-offline.enable ''
          [[tls.certificates]]
          certFile = "${zwift-offline}/ssl/cert-zwift-com.pem"
          keyFile = "${zwift-offline}/ssl/key-zwift-com.pem"
        ''}
      '';
    };

    localModules.containers.networks.proxy = {};
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
      dynamicConfigFile = config.sops.templates."traefik-dynamic.toml".path;
    };
  };
}
