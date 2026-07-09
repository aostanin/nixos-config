{
  lib,
  pkgs,
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

  # Boot pins the exit node by IP (resolves without a netmap; a stale/rotated IP
  # blackholes egress rather than leaking). Once the node is healthy the netmap
  # is loaded, so re-pin by hostname — that resolves to a node ID, which
  # tailscale follows across IP rotations. Retry: `set` reports "no node found in
  # netmap" until the peer streams in.
  setExitNode = pkgs.writeShellScript "vpn-set-exit-node" ''
    host="$(cat ${config.sops.secrets."containers/vpn/exit_node_hostname".path})"
    for i in $(seq 1 10); do
      if ${pkgs.podman}/bin/podman exec ${name} tailscale set --exit-node="$host"; then
        echo "vpn: exit node pinned to $host"
        exit 0
      fi
      echo "vpn: netmap not ready for $host, retry $i/10"
      sleep 2
    done
    echo "vpn: WARNING failed to pin exit node $host; egress stays blackholed at the boot IP" >&2
    exit 0
  '';
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
      "containers/vpn/exit_node_hostname" = {};
    };

    systemd.services."podman-${name}".serviceConfig.ExecStartPost = ["${setExitNode}"];

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
        TS_ENABLE_HEALTH_CHECK = "true";
        TS_LOCAL_ADDR_PORT = "127.0.0.1:9002";
      };
      volumes.data.destination = lib.mkIf (!cfg.ephemeral) "/var/lib/tailscale";
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      healthcheck = {
        cmd = "wget -q --tries=1 --spider http://127.0.0.1:9002/healthz";
        startPeriod = "30s";
      };
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
