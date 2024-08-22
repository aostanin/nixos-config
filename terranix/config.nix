{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (import ../secrets) domain;
  secrets = import ../secrets/terranix;
in {
  terraform.required_providers = {
    # Workaround for https://github.com/NixOS/nixpkgs/issues/283015#issuecomment-1904909598
    cloudflare.source = "registry.terraform.io/cloudflare/cloudflare";
    local.source = "registry.terraform.io/hashicorp/local";
    null.source = "registry.terraform.io/hashicorp/null";
    random.source = "registry.terraform.io/hashicorp/random";
    sops.source = "registry.terraform.io/carlpett/sops";
    tailscale.source = "registry.terraform.io/tailscale/tailscale";
  };

  data.sops_file.secrets.source_file = toString ../secrets/sops/secrets.enc.yaml;

  provider.cloudflare.api_token = "\${data.sops_file.secrets.data[\"cloudflare.api_token\"]}";

  provider.tailscale.api_key = "\${data.sops_file.secrets.data[\"tailscale.api_key\"]}";

  resource.cloudflare_record = let
    servers = lib.filterAttrs (n: v: v.tunnelId != null) secrets.servers;
  in
    lib.mkMerge ([
        (lib.mapAttrs' (server: config:
          lib.attrsets.nameValuePair "${server}-cf" {
            allow_overwrite = true;
            zone_id = "\${data.sops_file.secrets.data[\"cloudflare.zones.${domain}.zone_id\"]}";
            type = "CNAME";
            name = "${server}-cf";
            value = "${config.tunnelId}.cfargotunnel.com";
            proxied = true;
          })
        servers)
      ]
      ++ builtins.attrValues (builtins.mapAttrs (server: config: (builtins.listToAttrs (builtins.map (subdomain: {
          name = builtins.replaceStrings ["."] ["_"] subdomain;
          value = {
            allow_overwrite = true;
            zone_id = "\${data.sops_file.secrets.data[\"cloudflare.zones.${domain}.zone_id\"]}";
            type = "CNAME";
            name = subdomain;
            value = "${server}-cf.${domain}";
            proxied = true;
          };
        })
        config.subdomains)))
      servers));

  resource.tailscale_tailnet_key.nixos_auth_key = {
    reusable = true;
    preauthorized = true;
    description = "NixOS Terraform";
  };

  output.tailscale_auth_key = {
    value = config.resource.tailscale_tailnet_key.nixos_auth_key "key";
    sensitive = true;
  };

  data.tailscale_devices.devices = {};

  resource.tailscale_acl.acl = {
    acl = builtins.toJSON {
      tagOwners = {
        "tag:server" = ["autogroup:admin"];
      };
      acls = [
        {
          action = "accept";
          src = ["*"];
          dst = ["*:*"];
        }
      ];
      ssh = [
        {
          action = "check";
          src = ["autogroup:member"];
          dst = ["autogroup:self"];
          users = ["autogroup:nonroot" "root"];
        }
      ];
      nodeAttrs = lib.mapAttrsToList (n: v: {
        target = [(config.data.tailscale_device.${n} "addresses[0]")];
        attr = ["mullvad"];
      }) (lib.filterAttrs (n: v: v.enableMullvad) secrets.tailscale.devices);
    };
    overwrite_existing_content = true;
  };

  resource.tailscale_dns_preferences.preferences = {
    magic_dns = true;
  };

  resource.tailscale_dns_nameservers.nameservers = {
    nameservers = [
      (config.data.tailscale_device.roan "addresses[0]")
    ];
  };

  data.tailscale_device =
    lib.mapAttrs (n: v: {
      name = "${n}.${secrets.tailscale.tailnetName}";
    })
    secrets.tailscale.devices;

  resource.tailscale_device_key =
    lib.mapAttrs (n: v: {
      device_id = config.data.tailscale_device.${n} "id";
      key_expiry_disabled = true;
    })
    secrets.tailscale.devices;

  resource.tailscale_device_tags =
    lib.mapAttrs (n: v: {
      device_id = config.data.tailscale_device.${n} "id";
      tags =
        []
        ++ lib.optionals v.isServer ["tag:server"];
    })
    secrets.tailscale.devices;

  resource.tailscale_device_subnet_routes =
    lib.mapAttrs (n: v: {
      device_id = config.data.tailscale_device.${n} "id";
      routes = v.routes;
    })
    secrets.tailscale.devices;

  tunnels = {
    # TODO: Setup all tunnels this way
    roan.accountId = "\${data.sops_file.secrets.data[\"cloudflare.account_id\"]}";
    mareg.accountId = "\${data.sops_file.secrets.data[\"cloudflare.account_id\"]}";
  };

  resource.local_sensitive_file.secrets-json = {
    content = builtins.toJSON {
      tailscale.auth_key = config.output.tailscale_auth_key.value;
      cloudflare.tunnels = {
        roan.tunnel_token = config.output.tunnel_token_roan.value;
        mareg.tunnel_token = config.output.tunnel_token_mareg.value;
      };
    };
    filename = "secrets/secrets.json";
    file_permission = "0640";
  };

  resource.null_resource.sops-encrypt-secrets-json = {
    depends_on = ["local_sensitive_file.secrets-json"];

    triggers = {
      secrets_json_updated = config.resource.local_sensitive_file.secrets-json "id";
    };

    provisioner.local-exec = {
      command = "${pkgs.sops}/bin/sops --encrypt --output secrets/secrets.enc.json secrets/secrets.json";
    };
  };

  resource.local_file.tailscale-json = {
    content = builtins.toJSON {
      tailscale.hosts =
        lib.mapAttrs (n: v: {
          name = config.data.tailscale_device.${n} "name";
          address = config.data.tailscale_device.${n} "addresses[0]";
          address6 = config.data.tailscale_device.${n} "addresses[1]";
        })
        secrets.tailscale.devices;
    };
    filename = "secrets/tailscale.json";
    file_permission = "0640";
  };
}
