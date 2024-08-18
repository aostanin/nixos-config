{
  lib,
  config,
  ...
}: let
  containersCfg = config.localModules.containers;
  cfg = config.localModules.containers.containers.traefik;
in {
  options.localModules.containers.containers.traefik = {
    enable = lib.mkEnableOption "traefik";

    # TODO: Lib?
    volumes.config = lib.mkOption {
      type = lib.types.str;
      default = "${containersCfg.defaultStoragePath}/traefik";
    };
  };

  config = lib.mkIf cfg.enable (let
    inherit (containersCfg) domain host;
  in {
    localModules.containers.networks.proxy.driver = "bridge";

    # TODO: Lib?
    systemd.user.tmpfiles.rules = [
      "d '${cfg.volumes.config}' - container container - -"
    ];

    systemd.user.sockets = {
      traefik-http = {
        Socket = {
          ListenStream = "8080";
          FileDescriptorName = "web";
          Service = "podman-traefik.service";
        };

        Install = {
          WantedBy = ["sockets.target"];
        };
      };
      traefik-https = {
        Socket = {
          ListenStream = "8443";
          FileDescriptorName = "websecure";
          Service = "podman-traefik.service";
        };

        Install = {
          WantedBy = ["sockets.target"];
        };
      };
    };

    sops.secrets = {
      "traefik/env" = {};
      "traefik/labels" = {};
    };

    services.podman.containers.traefik = {
      image = "docker.io/library/traefik:v3.1";
      networks = ["proxy"];
      command = lib.concatStringsSep " " [
        "--accesslog=true"
        "--log.level=DEBUG"

        "--providers.docker.network=proxy"
        "--providers.docker.exposedByDefault=false"

        "--serversTransport.insecureSkipVerify=true"

        "--certificatesResolvers.default.acme.storage=/config/acme.json"
        "--certificatesResolvers.default.acme.dnsChallenge=true"
        "--certificatesResolvers.default.acme.dnsChallenge.provider=cloudflare"
        "--certificatesResolvers.default.acme.dnsChallenge.resolvers=1.1.1.1:53,8.8.8.8:53"

        "--entryPoints.web.address=:80"
        "--entrypoints.web.http.redirections.entrypoint.to=websecure"
        "--entrypoints.web.http.redirections.entrypoint.scheme=https"

        "--entryPoints.websecure.address=:443"
        "--entryPoints.websecure.http.tls=true"
        "--entryPoints.websecure.http.tls.certResolver=default"
        "--entryPoints.websecure.http.tls.domains[0].main=${domain}"
        "--entryPoints.websecure.http.tls.domains[0].sans=*.${domain},${host}.lan.${domain},*.${host}.lan.${domain},${host}.ts.${domain},*.${host}.ts.${domain}"
      ];
      labels = [
        "traefik.http.middlewares.authelia.forwardAuth.authResponseHeaders=Remote-User,Remote-Groups,Remote-Email,Remote-Name"
        "traefik.http.middlewares.authelia.forwardAuth.trustForwardHeader=true"
      ];
      volumes = [
        "%t/podman/podman.sock:/var/run/docker.sock:ro"
        "${cfg.volumes.config}:/config"
      ];
      extraOptions = ["--label-file=${config.sops.secrets."traefik/labels".path}"];
      environmentFile = config.sops.secrets."traefik/env".path;
      serviceConfig.Sockets = "traefik-http.socket traefik-https.socket";
    };
  });
}
