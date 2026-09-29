{
  config,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules.tailscale;
  device = secrets.terranix.tailscale.devices.${config.networking.hostName} or {};
  # Always passed, even when empty: `tailscale set` only changes the flags it's
  # given, so leaving one out would keep a stale advertisement.
  advertiseFlags = [
    "--advertise-exit-node=${lib.boolToString cfg.advertiseExitNode}"
    "--advertise-routes=${lib.concatStringsSep "," cfg.advertiseRoutes}"
  ];
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

    tags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      # Match what terraform assigns, so a re-registration doesn't change them.
      default =
        if device.isServer or false
        then ["tag:server"]
        else ["tag:managed"];
      description = "Tags to register with; OAuth-registered nodes must be tagged.";
    };

    advertiseExitNode = lib.mkEnableOption "advertising this node as an exit node";

    advertiseRoutes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Subnet routes to advertise.";
    };

    extraFlags = lib.mkOption {
      description = "Extra flags.";
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["--advertise-exit-node"];
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."tailscale/client_secret" = {};

    services.tailscale = {
      enable = true;
      openFirewall = true;
      # An OAuth client secret registers the node directly, so there's no
      # expiring auth key to regenerate.
      authKeyFile = config.sops.secrets."tailscale/client_secret".path;
      authKeyParameters.preauthorized = true;
      # `tailscale set` rejects --advertise-tags.
      extraUpFlags = advertiseFlags ++ cfg.extraFlags ++ ["--advertise-tags=${lib.concatStringsSep "," cfg.tags}"];
      extraSetFlags = advertiseFlags ++ cfg.extraFlags;
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
