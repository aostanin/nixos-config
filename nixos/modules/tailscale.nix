{
  config,
  lib,
  sopsFiles,
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

    extraFlags = lib.mkOption {
      description = "Extra flags.";
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["--advertise-exit-node"];
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."tailscale/auth_key".sopsFile = sopsFiles.terranix;

    services.tailscale = {
      enable = true;
      openFirewall = true;
      authKeyFile = config.sops.secrets."tailscale/auth_key".path;
      extraUpFlags = cfg.extraFlags;
      extraSetFlags = cfg.extraFlags;
      useRoutingFeatures =
        if (cfg.isClient && cfg.isServer)
        then "both"
        else if cfg.isClient
        then "client"
        else if cfg.isServer
        then "server"
        else "none";
    };

    systemd.services.tailscaled.environment = {
      # TS_DEBUG_ALWAYS_USE_DERP = "true";
      TS_DISCO_PONG_IPV4_DELAY = "300ms"; # Bias towards IPv6
    };

    # TODO: With resolved, TailScale DNS is used alongside system DNS.
    # The host will resolve with TailScale DNS, but containers will use the
    # original DNS for some reason.
    networking.nameservers = ["100.100.100.100"];
  };
}
