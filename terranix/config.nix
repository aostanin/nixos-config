{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (import ../secrets) domain;
  secrets = import ../secrets/terranix;

  tailscaleDevice = name: attribute:
    lib.tfRef "local.tailscale_devices.${name}.${attribute}";
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
        # TODO: Only public
        config.subdomains)))
      servers));

  resource.tailscale_tailnet_key.nixos_auth_key = {
    reusable = true;
    ephemeral = false;
    preauthorized = true;
    tags = ["tag:managed"];
    description = "NixOS Terraform";
  };

  output.tailscale_auth_key = {
    value = config.resource.tailscale_tailnet_key.nixos_auth_key "key";
    sensitive = true;
  };

  resource.tailscale_tailnet_key.nixos_auth_key_ephemeral = {
    reusable = true;
    ephemeral = true;
    preauthorized = true;
    tags = ["tag:ephemeral"];
    description = "NixOS Terraform Ephemeral";
  };

  output.tailscale_auth_key_ephemeral = {
    value = config.resource.tailscale_tailnet_key.nixos_auth_key_ephemeral "key";
    sensitive = true;
  };

  data.tailscale_devices.devices = {};

  locals.tailscale_tailnet_suffix = ".${secrets.tailscale.tailnetName}";
  locals.tailscale_devices = ''    ''${{
    for device in data.tailscale_devices.devices.devices :
      trimsuffix(device.name, local.tailscale_tailnet_suffix) => {
        id = device.id
        name = device.name
        address = device.addresses[0]
        address6 = device.addresses[1]
      }
    }}'';

  resource.tailscale_acl.acl = {
    acl = builtins.toJSON {
      tagOwners = {
        "tag:server" = ["autogroup:admin"];
        "tag:managed" = ["autogroup:admin"];
        "tag:ephemeral" = ["autogroup:admin"];
        "tag:mullvad" = ["tag:managed" "tag:ephemeral"];
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
      nodeAttrs =
        lib.mapAttrsToList (n: v: {
          target = [(tailscaleDevice n "address")];
          attr = ["mullvad"];
        }) (lib.filterAttrs (n: v: v.enableMullvad) secrets.tailscale.devices)
        ++ [
          {
            target = ["tag:mullvad"];
            attr = ["mullvad"];
          }
        ];
    };
    overwrite_existing_content = true;
  };

  resource.tailscale_dns_preferences.preferences = {
    magic_dns = true;
  };

  resource.tailscale_dns_nameservers.nameservers = {
    nameservers = [
      (tailscaleDevice "roan" "address")
      (tailscaleDevice "vps-oci2" "address")
    ];
  };

  resource.tailscale_device_key =
    lib.mapAttrs (n: v: {
      count = lib.tfRef "contains(keys(local.tailscale_devices), \"${n}\") ? 1 : 0";
      device_id = tailscaleDevice n "id";
      key_expiry_disabled = true;
    })
    secrets.tailscale.devices;

  resource.tailscale_device_tags =
    lib.mapAttrs (n: v: {
      count = lib.tfRef "contains(keys(local.tailscale_devices), \"${n}\") ? 1 : 0";
      device_id = tailscaleDevice n "id";
      tags = lib.optional v.isServer "tag:server";
    })
    secrets.tailscale.devices;

  resource.tailscale_device_subnet_routes =
    lib.mapAttrs (n: v: {
      count = lib.tfRef "contains(keys(local.tailscale_devices), \"${n}\") ? 1 : 0";
      device_id = tailscaleDevice n "id";
      routes = v.routes;
    })
    secrets.tailscale.devices;

  tunnels = let
    accountId = "\${data.sops_file.secrets.data[\"cloudflare.account_id\"]}";
  in {
    # TODO: Set up each service separately
    # TODO: Limit home assistant to only Google IPs https://community.home-assistant.io/t/expose-home-assistant-for-google-ips-only-ipv4-only/184646/2
    elena.accountId = accountId;
    mareg.accountId = accountId;
    roan.accountId = accountId;
    vps-oci1.accountId = accountId;
    vps-oci2.accountId = accountId;
    vps-oci-arm1.accountId = accountId;
  };

  resource.local_sensitive_file.secrets-json = {
    content = builtins.toJSON {
      tailscale = {
        auth_key = config.output.tailscale_auth_key.value;
        auth_key_ephemeral = config.output.tailscale_auth_key_ephemeral.value;
      };
      cloudflare.tunnels = {
        elena.tunnel_token = config.output.tunnel_token_mareg.value;
        mareg.tunnel_token = config.output.tunnel_token_mareg.value;
        roan.tunnel_token = config.output.tunnel_token_roan.value;
        vps-oci2.tunnel_token = config.output.tunnel_token_vps-oci2.value;
        vps-oci1.tunnel_token = config.output.tunnel_token_vps-oci1.value;
        vps-oci-arm1.tunnel_token = config.output.tunnel_token_vps-oci-arm1.value;
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
      command = ''
        cp secrets/secrets.json ../secrets/sops/terranix.enc.yaml && \
        ${pkgs.sops}/bin/sops --encrypt --output ../secrets/sops/terranix.enc.yaml ../secrets/sops/terranix.enc.yaml
      '';
    };
  };

  locals.tailscale_json = "\${{ tailscale = { hosts = local.tailscale_devices } }}";
  resource.local_file.tailscale-json = {
    content = lib.tfRef "jsonencode(local.tailscale_json)";
    filename = "../secrets/network/tailscale.json";
    file_permission = "0640";
  };
}
