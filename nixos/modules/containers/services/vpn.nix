{
  lib,
  config,
  sopsFiles,
  ...
}: let
  name = "vpn";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    hostname = lib.mkOption {
      type = lib.types.str;
      default = "container-${config.networking.hostName}";
      description = "TailScale hostname.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "tailscale/auth_key_ephemeral".sopsFile = sopsFiles.terranix;
      "containers/vpn/exit_node" = {};
    };

    sops.templates."${name}.env".content = ''
      TS_AUTHKEY=${config.sops.placeholder."tailscale/auth_key_ephemeral"}
      TS_EXTRA_ARGS=--exit-node=${config.sops.placeholder."containers/vpn/exit_node"} --exit-node-allow-lan-access=false --accept-routes=false --advertise-tags=tag:mullvad
    '';

    localModules.containers.containers.${name} = {
      raw.image = "docker.io/tailscale/tailscale:latest";
      raw.environment = {
        TS_ACCEPT_DNS = "false";
        TS_HOSTNAME = "container-${config.networking.hostName}";
        TS_USERSPACE = "false"; # Needed to use exit node
      };
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      raw.extraOptions = [
        "--device=/dev/net/tun"
        "--cap-add=net_admin"
        "--cap-add=sys_module"
        "--dns=1.1.1.1"
        "--dns=8.8.8.8"
      ];
    };
  };
}
