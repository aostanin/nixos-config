{
  lib,
  config,
  sopsFiles,
  ...
}: let
  name = "vpn";
  cfg = config.localModules.containers.services.${name};

  authKey =
    if cfg.ephemeral
    then "tailscale/auth_key_ephemeral"
    else "tailscale/auth_key";
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    hostname = lib.mkOption {
      type = lib.types.str;
      default = "container-${config.networking.hostName}";
      description = "TailScale hostname.";
    };

    ephemeral = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run as an ephemeral node.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      ${authKey}.sopsFile = sopsFiles.terranix;
      "containers/vpn/exit_node" = {};
    };

    sops.templates."${name}.env".content = ''
      TS_AUTHKEY=${config.sops.placeholder.${authKey}}
      TS_EXTRA_ARGS=--exit-node=${config.sops.placeholder."containers/vpn/exit_node"} --exit-node-allow-lan-access=false --accept-routes=false --advertise-tags=tag:mullvad
    '';

    localModules.containers.containers.${name} = {
      raw.image = "docker.io/tailscale/tailscale:latest";
      raw.environment = {
        TS_ACCEPT_DNS = "false";
        TS_HOSTNAME = "container-${config.networking.hostName}";
        TS_STATE_DIR = "/var/lib/tailscale";
        TS_USERSPACE = "false"; # Needed to use exit node
      };
      volumes.data.destination = lib.mkIf (!cfg.ephemeral) "/var/lib/tailscale";
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      raw.extraOptions = [
        "--device=/dev/net/tun"
        "--cap-add=NET_ADMIN"
        "--cap-add=SYS_MODULE"
        "--cap-add=NET_RAW"
        "--dns=1.1.1.1"
        "--dns=8.8.8.8"
      ];
    };
  };
}
