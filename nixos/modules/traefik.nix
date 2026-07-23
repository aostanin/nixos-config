{
  config,
  lib,
  secrets,
  localLib,
  self,
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

    dnsOverTls = {
      enable = lib.mkEnableOption ''
        a public DNS-over-TLS (DoT) endpoint on :853. Traefik terminates the TLS
        (reusing the Cloudflare cert resolver) and forwards the decrypted
        DNS-over-TCP stream to a plain backend. Access is gated by hostSni'';

      hostSni = lib.mkOption {
        type = lib.types.str;
        default = secrets.dns.hostname;
        description = ''
          Secret SNI hostname that gates access — only this HostSNI is routed,
          everything else on :853 is dropped. A hard-to-guess label under
          dns.''${domain}; defaults to the one in secrets.
        '';
      };

      backend = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1:5300";
        description = "Plain DNS-over-TCP backend (AdGuard) to forward decrypted queries to.";
      };
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

    systemd.services.traefik = lib.mkIf config.localModules.containers.enable {
      after = ["podman-proxy-network.service"];
      requires = ["podman-proxy-network.service"];
    };

    services.traefik = {
      enable = true;
      group =
        lib.mkIf config.localModules.containers.enable
        (
          if config.virtualisation.docker.enable
          then "docker"
          else "podman"
        );
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
        providers.docker = lib.mkIf config.localModules.containers.enable {
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
        entryPoints =
          {
            web = {
              address = ":80";
              http.redirections.entrypoint = {
                to = "websecure";
                scheme = "https";
              };
            };
            websecure = {
              address = ":443";
              transport.respondingTimeouts = {
                readTimeout = "600s";
                idleTimeout = "600s";
              };
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
          }
          // lib.optionalAttrs cfg.dnsOverTls.enable {
            dns-tls.address = ":853";
          };
      };
      dynamicConfigOptions =
        {
          http.middlewares.auth.basicAuth.usersFile = config.sops.secrets."traefik/basic_auth_users".path;

          http.middlewares.authelia.forwardAuth = let
            autheliaHost = localLib.hostRunningService "authelia" self.nixosConfigurations;
          in {
            address = "http://${secrets.network.tailscale.hosts.${autheliaHost}.address}:9091/api/authz/forward-auth";
            authResponseHeaders = "Remote-User,Remote-Groups,Remote-Email,Remote-Name";
            trustForwardHeader = "true";
          };
        }
        // lib.optionalAttrs cfg.dnsOverTls.enable {
          # DoT: terminate TLS with the wildcard cert, gate on the secret HostSNI,
          # forward the decrypted DNS-over-TCP to the plain backend (AdGuard).
          # DoT clients negotiate the "dot" ALPN, which Traefik's default TLS
          # options reject — enable it explicitly on this router.
          tls.options.dot.alpnProtocols = ["dot"];
          tcp.routers.dns = {
            entryPoints = ["dns-tls"];
            rule = "HostSNI(`${cfg.dnsOverTls.hostSni}`)";
            tls = {
              certResolver = "default";
              options = "dot";
              domains = [
                {
                  main = "dns.${cfg.domain}";
                  sans = ["*.dns.${cfg.domain}"];
                }
              ];
            };
            service = "adguard-dns";
          };
          tcp.services.adguard-dns.loadBalancer.servers = [{address = cfg.dnsOverTls.backend;}];
        };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.dnsOverTls.enable [853];
  };
}
