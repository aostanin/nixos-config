{
  lib,
  config,
  pkgs,
  secrets,
  ...
}: let
  name = "caddy";
  cfg = config.localModules.containers.services.${name};
  domain = secrets.domain;

  caddyfile = pkgs.writeText "Caddyfile" ''
    :80 {
      handle /.well-known/matrix/server {
        header Content-Type application/json
        respond `{"m.server": "matrix.${domain}:443"}`
      }

      handle /.well-known/matrix/client {
        header Content-Type application/json
        header Access-Control-Allow-Origin *
        respond `{"m.homeserver": {"base_url": "https://matrix.${domain}"}, "org.matrix.msc3575.proxy": {"url": "https://matrix-syncv3.${domain}"}}`
      }

      handle /.well-known/lnurlp/* {
        reverse_proxy https://lnbits.${domain} {
          header_up Host lnbits.${domain}
        }
      }

      handle /lnurlp/* {
        reverse_proxy https://lnbits.${domain} {
          header_up Host lnbits.${domain}
        }
      }

      respond "Not Found" 404
    }
  '';
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/library/caddy:alpine";
      raw.volumes = [
        "${caddyfile}:/etc/caddy/Caddyfile:ro"
      ];
      proxy = {
        enable = true;
        hosts = [domain];
        port = 80;
        default.enable = true;
      };
    };
  };
}
