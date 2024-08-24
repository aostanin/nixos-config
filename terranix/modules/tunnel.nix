{
  config,
  lib,
  ...
}: let
  tunnels = config.tunnels;

  tunnelSubmodule = lib.types.submodule {
    options = {
      accountId = lib.mkOption {
        type = lib.types.str;
      };

      service = lib.mkOption {
        type = lib.types.str;
        default = "https://traefik:443";
      };
    };
  };
in {
  options = {
    tunnels = lib.mkOption {
      type = lib.types.attrsOf tunnelSubmodule;
      default = {};
    };
  };

  config = {
    resource = lib.mkMerge (lib.mapAttrsToList (tunnelName: tunnelConfig: {
        random_password."${tunnelName}_tunnel_secret" = {
          length = 64;
        };

        cloudflare_tunnel."${tunnelName}" = {
          account_id = tunnelConfig.accountId;
          name = tunnelName;
          secret = "\${base64sha256(random_password.${tunnelName}_tunnel_secret.result)}";
        };

        cloudflare_tunnel_config."${tunnelName}" = {
          tunnel_id = config.resource.cloudflare_tunnel."${tunnelName}" "id";
          account_id = tunnelConfig.accountId;
          config = {
            origin_request.no_tls_verify = true;
            ingress_rule = [
              {
                inherit (tunnelConfig) service;
              }
            ];
          };
        };
      })
      tunnels);

    # TODO: Export to nix module?
    output = lib.mkMerge (lib.mapAttrsToList (tunnelName: tunnelConfig: {
        "tunnel_id_${tunnelName}".value = config.resource.cloudflare_tunnel."${tunnelName}" "id";

        "tunnel_token_${tunnelName}" = {
          value = config.resource.cloudflare_tunnel."${tunnelName}" "tunnel_token";
          sensitive = true;
        };
      })
      tunnels);
  };
}
