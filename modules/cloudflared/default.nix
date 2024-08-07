{
  lib,
  pkgs,
  config,
  sopsFiles,
  ...
}: let
  cfg = config.localModules.cloudflared;
in {
  options.localModules.cloudflared = {
    enable = lib.mkEnableOption "cloudflared";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."cloudflare/tunnels/${config.networking.hostName}/tunnel_token".sopsFile = sopsFiles.terranix;

    systemd.services.cloudflared = {
      after = ["network.target" "network-online.target"];
      wants = ["network.target" "network-online.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        LoadCredential = [
          "token:${config.sops.secrets."cloudflare/tunnels/${config.networking.hostName}/tunnel_token".path}"
        ];
        Environment = [
          "TOKEN_FILE=%d/token"
        ];
        User = "cloudflared";
        Group = "cloudflared";
        Restart = "on-failure";
      };
      script = "${lib.getExe pkgs.cloudflared} tunnel --no-autoupdate run --token $(cat $TOKEN_FILE)";
    };

    users = {
      users.cloudflared = {
        group = "cloudflared";
        isSystemUser = true;
      };

      groups.cloudflared = {};
    };
  };
}
