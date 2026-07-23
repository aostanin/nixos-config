{
  config,
  lib,
  pkgs,
  self,
  localLib,
  secrets,
  ...
}: let
  domain = secrets.domain;
  ingressDnsNames = localLib.dnsNamesByHost domain self.nixosConfigurations;

  tailscaleDevice = name: attribute:
    lib.tfRef "local.tailscale_devices.${name}.${attribute}";
in {
  terraform.required_providers = {
    cloudflare.source = "cloudflare/cloudflare";
    local.source = "local";
    null.source = "null";
    random.source = "random";
    sops.source = "carlpett/sops";
    tailscale.source = "tailscale/tailscale";
  };

  data.sops_file.secrets.source_file = toString ../secrets/sops/secrets.enc.yaml;

  provider.cloudflare.api_token = "\${data.sops_file.secrets.data[\"cloudflare.api_token\"]}";
  provider.tailscale.api_key = "\${data.sops_file.secrets.data[\"tailscale.api_key\"]}";

  resource.cloudflare_dns_record = let
    servers = lib.filterAttrs (n: v: v.tunnelId != null) secrets.terranix.servers;
    zoneId = "\${data.sops_file.secrets.data[\"cloudflare.zones.${domain}.zone_id\"]}";

    # Public DNS-over-TLS endpoint (Android native Private DNS). Wildcard *.dns so
    # the secret client label never appears in DNS; proxied = false because DoT is
    # raw TLS and can't traverse Cloudflare's HTTP proxy. Both VPSes for failover.
    # IPs come from secrets so they stay out of the plaintext config.
    dotRecords = lib.listToAttrs (lib.concatLists (lib.mapAttrsToList (host: ip: [
        (lib.nameValuePair "dns-${host}-a" {
          zone_id = zoneId;
          type = "A";
          name = "*.dns";
          content = ip.ipv4;
          proxied = false;
          ttl = 300;
        })
        (lib.nameValuePair "dns-${host}-aaaa" {
          zone_id = zoneId;
          type = "AAAA";
          name = "*.dns";
          content = ip.ipv6;
          proxied = false;
          ttl = 300;
        })
      ])
      secrets.dns.endpoints));
  in
    lib.mkMerge ([
        (lib.mapAttrs' (server: config:
          lib.attrsets.nameValuePair "${server}-cf" {
            zone_id = zoneId;
            type = "CNAME";
            name = "${server}-cf";
            content = "${config.tunnelId}.cfargotunnel.com";
            proxied = true;
            ttl = 1; # Auto TTL when proxied
          })
        servers)
        dotRecords
      ]
      ++ builtins.attrValues (builtins.mapAttrs (server: _: (builtins.listToAttrs (builtins.map (fqdn: let
          recordName =
            if fqdn == domain
            then fqdn
            else lib.removeSuffix ".${domain}" fqdn;
        in {
          name = builtins.replaceStrings ["."] ["_"] recordName;
          value = {
            zone_id = "\${data.sops_file.secrets.data[\"cloudflare.zones.${domain}.zone_id\"]}";
            type = "CNAME";
            name = recordName;
            content = "${server}-cf.${domain}";
            proxied = true;
            ttl = 1; # Auto TTL when proxied
          };
        })
        (ingressDnsNames.${server} or []))))
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

  locals.tailscale_tailnet_suffix = ".${secrets.terranix.tailscale.tailnetName}";
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
      randomizeClientPort = true;
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
        }) (lib.filterAttrs (n: v: v.enableMullvad) secrets.terranix.tailscale.devices)
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

  # Split DNS, not global nameservers: only ${domain} queries go to the tailnet
  # resolvers; everything else uses each device's own DNS (e.g. the phone's native
  # DoT). Avoids tunnelling all DNS through Tailscale.
  resource.tailscale_dns_split_nameservers.internal = {
    domain = domain;
    nameservers = [
      (tailscaleDevice "elena" "address")
      (tailscaleDevice "vps-oci2" "address")
    ];
  };

  resource.tailscale_device_key =
    lib.mapAttrs (n: v: {
      count = lib.tfRef "contains(keys(local.tailscale_devices), \"${n}\") ? 1 : 0";
      device_id = tailscaleDevice n "id";
      key_expiry_disabled = true;
    })
    secrets.terranix.tailscale.devices;

  resource.tailscale_device_tags =
    lib.mapAttrs (n: v: {
      count = lib.tfRef "contains(keys(local.tailscale_devices), \"${n}\") ? 1 : 0";
      device_id = tailscaleDevice n "id";
      tags = lib.optional v.isServer "tag:server";
    })
    secrets.terranix.tailscale.devices;

  resource.tailscale_device_subnet_routes =
    lib.mapAttrs (n: v: {
      count = lib.tfRef "contains(keys(local.tailscale_devices), \"${n}\") ? 1 : 0";
      device_id = tailscaleDevice n "id";
      routes = v.routes;
    })
    secrets.terranix.tailscale.devices;

  tunnels = let
    accountId = "\${data.sops_file.secrets.data[\"cloudflare.account_id\"]}";
  in {
    # TODO: Set up each service separately
    # TODO: Limit home assistant to only Google IPs https://community.home-assistant.io/t/expose-home-assistant-for-google-ips-only-ipv4-only/184646/2
    elena.accountId = accountId;
    every-router.accountId = accountId;
    mareg.accountId = accountId;
    pikvm.accountId = accountId;
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
        elena.tunnel_token = config.output.tunnel_token_elena.value;
        every-router.tunnel_token = config.output.tunnel_token_every-router.value;
        mareg.tunnel_token = config.output.tunnel_token_mareg.value;
        pikvm.tunnel_token = config.output.tunnel_token_pikvm.value;
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
