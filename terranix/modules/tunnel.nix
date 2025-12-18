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
        default = "https://127.0.0.1:443";
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
        cloudflare_zero_trust_tunnel_cloudflared."${tunnelName}" = {
          account_id = tunnelConfig.accountId;
          name = tunnelName;
          config_src = "cloudflare";
        };

        cloudflare_zero_trust_tunnel_cloudflared_config."${tunnelName}" = {
          tunnel_id = config.resource.cloudflare_zero_trust_tunnel_cloudflared."${tunnelName}" "id";
          account_id = tunnelConfig.accountId;
          config = {
            origin_request.no_tls_verify = true;
            ingress = [
              {
                inherit (tunnelConfig) service;
              }
            ];
          };
        };
      })
      tunnels);

    data.cloudflare_zero_trust_tunnel_cloudflared_token = lib.mkMerge (lib.mapAttrsToList (tunnelName: tunnelConfig: {
        "${tunnelName}" = {
          account_id = tunnelConfig.accountId;
          tunnel_id = config.resource.cloudflare_zero_trust_tunnel_cloudflared."${tunnelName}" "id";
        };
      })
      tunnels);

    output = lib.mkMerge (lib.mapAttrsToList (tunnelName: tunnelConfig: {
        "tunnel_id_${tunnelName}".value = config.resource.cloudflare_zero_trust_tunnel_cloudflared."${tunnelName}" "id";

        "tunnel_token_${tunnelName}" = {
          value = config.data.cloudflare_zero_trust_tunnel_cloudflared_token."${tunnelName}" "token";
          sensitive = true;
        };
      })
      tunnels);
  };
}
