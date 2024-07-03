{
  config,
  pkgs,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules.tailscale;
in {
  options.localModules.tailscale = {
    enable = lib.mkEnableOption "tailscale";

    isClient = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = ''
        Node is a client.
      '';
    };

    isServer = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = ''
        Node is a server.
      '';
    };

    extraSetFlags = lib.mkOption {
      description = "Extra flags to pass to {command}`tailscale set`.";
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["--advertise-exit-node"];
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."tailscale/auth_key" = {};

    services.tailscale = {
      enable = true;
      openFirewall = true;
      authKeyFile = config.sops.secrets."tailscale/auth_key".path;
      useRoutingFeatures =
        if (cfg.isClient && cfg.isServer)
        then "both"
        else if cfg.isClient
        then "client"
        else if cfg.isServer
        then "server"
        else "none";
    };

    # TODO: Remove once stable
    systemd.services.tailscaled-set = lib.mkIf (cfg.extraSetFlags != []) {
      after = ["tailscaled.service"];
      wants = ["tailscaled.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
      };
      script = ''
        ${lib.getExe config.services.tailscale.package} set ${lib.escapeShellArgs cfg.extraSetFlags}
      '';
    };
  };
}
