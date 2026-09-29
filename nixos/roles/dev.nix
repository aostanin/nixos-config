{
  config,
  lib,
  pkgs,
  inputs,
  secrets,
  ...
}: let
  cfg = config.roles.dev;
  inherit (config.networking) hostName;
in {
  imports = [inputs.paseo.nixosModules.default];

  options.roles.dev = {
    enable = lib.mkEnableOption "a development environment driven through Paseo";

    publicHostname = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      example = "paseo.example.com";
      description = "Hostname Paseo is reverse-proxied under; workspace dev servers get subdomains of it.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."paseo/password" = {};
    sops.templates."paseo.env" = {
      content = "PASEO_PASSWORD=${config.sops.placeholder."paseo/password"}";
      owner = secrets.user.username;
    };

    services.paseo = {
      enable = true;
      # Upstream's install copies node_modules/node-pty/prebuilds/, but node-pty
      # lives under packages/server/node_modules, so terminals can't load pty.node.
      package = inputs.paseo.packages.${pkgs.stdenv.hostPlatform.system}.paseo.overrideAttrs (old: {
        postInstall =
          (old.postInstall or "")
          + ''
            plat=$(node -p 'process.platform + "-" + process.arch')
            for pty in $(find . -path ./node_modules/.cache -prune -o -type d -name node-pty -print); do
              if [ -d "$pty/prebuilds/$plat" ] && [ -d "$out/lib/paseo/$pty" ]; then
                mkdir -p "$out/lib/paseo/$pty/prebuilds"
                cp -a "$pty/prebuilds/$plat" "$out/lib/paseo/$pty/prebuilds/"
              fi
            done
          '';
      });
      user = secrets.user.username;
      group = "users";
      # Clients connect over the tailnet; the password guards the LAN side.
      listenAddress = "0.0.0.0";
      relay.enable = false;
      hostnames =
        [
          hostName
          "${hostName}.${secrets.terranix.tailscale.tailnetName}"
        ]
        ++ lib.optionals (cfg.publicHostname != null) [
          cfg.publicHostname
          ".${cfg.publicHostname}"
        ];
      environment =
        {
          PASEO_WEB_UI_ENABLED = "true";
        }
        // lib.optionalAttrs (cfg.publicHostname != null) {
          PASEO_SERVICE_PROXY_PUBLIC_BASE_URL = "https://${cfg.publicHostname}";
        };
    };

    systemd.services.paseo.serviceConfig.EnvironmentFile = config.sops.templates."paseo.env".path;
  };
}
