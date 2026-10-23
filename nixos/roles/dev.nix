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
      description = "Hostname Paseo's web UI is reverse-proxied under.";
    };

    appsHostname = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      example = "paseoapps.example.com";
      description = ''
        Base for workspace dev server URLs (`<script>--<project>.<appsHostname>`).
        Paseo reserves this name and its subdomains, so it can't be publicHostname.
      '';
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
      # Upstream's module defaults to its own flake package, bypassing the overlay.
      package = pkgs.paseo;
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
        ++ lib.optional (cfg.publicHostname != null) cfg.publicHostname;
      environment =
        {
          PASEO_WEB_UI_ENABLED = "true";
          PASEO_TRUSTED_PROXIES = "loopback";
        }
        // lib.optionalAttrs (cfg.appsHostname != null) {
          PASEO_SERVICE_PROXY_PUBLIC_BASE_URL = "https://${cfg.appsHostname}";
        };
    };

    systemd.services.paseo.serviceConfig.EnvironmentFile = config.sops.templates."paseo.env".path;
  };
}
