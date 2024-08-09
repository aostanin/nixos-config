{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.localModules.tailscale;
in {
  disabledModules = [
    "services/networking/tailscale.nix"
  ];

  imports = [
    # For extraSetFlags https://github.com/NixOS/nixpkgs/pull/309551
    # TODO: Remove once stable
    "${inputs.nixpkgs-unstable}/nixos/modules/services/networking/tailscale.nix"
  ];

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
    sops.secrets."tailscale/auth_key" = {};

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
  };
}
