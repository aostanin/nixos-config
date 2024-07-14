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
    # adguard.source = "registry.terraform.io/gmichels/adguard";
    cloudflare.source = "registry.terraform.io/cloudflare/cloudflare";
    tailscale.source = "registry.terraform.io/tailscale/tailscale";
    local.source = "registry.terraform.io/hashicorp/local";
    null.source = "registry.terraform.io/hashicorp/null";
    random.source = "registry.terraform.io/hashicorp/random";
  };

  # provider.adguard = {
  #   inherit (secrets.adguard) host username password;
  # };

  provider.cloudflare.api_token = secrets.cloudflare.apiToken;

  provider.tailscale.api_key = secrets.tailscale.apiKey;

  # TODO: Remove in favor of CoreDNS
  # resource.adguard_rewrite = let
  #   servers = lib.filterAttrs (n: v: v.lanIp != null) secrets.servers;
  # in
  #   lib.mkMerge (builtins.attrValues (builtins.mapAttrs (server: config: (builtins.listToAttrs (builtins.map (subdomain: {
  #       name = builtins.replaceStrings ["."] ["_"] subdomain;
  #       value = {
  #         domain = "${subdomain}.${domain}";
  #         answer = config.lanIp;
  #       };
  #     })
  #     config.subdomains)))
  #   servers));

  resource.cloudflare_record = let
    servers = lib.filterAttrs (n: v: v.tunnelId != null) secrets.servers;
  in
    lib.mkMerge ([
        (lib.mapAttrs' (server: config:
          lib.attrsets.nameValuePair "${server}-cf" {
            allow_overwrite = true;
            zone_id = secrets.cloudflare.zones.${domain}.zoneId;
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
            zone_id = secrets.cloudflare.zones.${domain}.zoneId;
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
    roan = {
      accountId = secrets.cloudflare.accountId;
    };
  };

  resource.local_sensitive_file.secrets-json = {
    content = builtins.toJSON {
      tailscale.auth_key = config.resource.tailscale_tailnet_key.nixos_auth_key "key";
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

  # resource.local_file.cloudflare-json = {
  #   content = builtins.toJSON {
  #     cloudflare.tunnels =
  #       lib.mapAttrs (n: v: {
  #         name = config.data.tailscale_device.${n} "name";
  #         address = config.data.tailscale_device.${n} "addresses[0]";
  #         address6 = config.data.tailscale_device.${n} "addresses[1]";
  #       })
  #       secrets.tailscale.devices;
  #   };
  #   filename = "secrets/cloudflare.json";
  #   file_permission = "0640";
  # };
}
