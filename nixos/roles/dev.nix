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
      hostnames = [
        hostName
        "${hostName}.${secrets.terranix.tailscale.tailnetName}"
      ];
      environment.PASEO_WEB_UI_ENABLED = "true";
    };

    systemd.services.paseo.serviceConfig.EnvironmentFile = config.sops.templates."paseo.env".path;
  };
}
