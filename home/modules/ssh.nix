{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: let
  cfg = config.localModules.ssh;

  mac = "andreis-macbook-pro";
  macTailscaleIp = secrets.network.tailscale.hosts.${mac}.address;
  # Picks the route per connection here rather than with a Match block:
  # eternal-terminal's ssh_config parser ignores Match conditions, so a Match
  # block's options leak onto every host.
  macProxy = pkgs.writeShellScript "${mac}-proxy" ''
    if tailscale status --json 2>/dev/null \
      | ${lib.getExe pkgs.jq} -e --arg ip ${macTailscaleIp} \
        '.Peer[] | select(.TailscaleIPs | index($ip)) | .Online' >/dev/null; then
      exec ${lib.getExe pkgs.netcat} ${macTailscaleIp} "$1"
    fi
    # A sleeping Mac is offline on the tailnet, but a connection to its LAN
    # address wakes it through the Bonjour sleep proxy.
    exec ssh -W ${secrets.network.home.hosts.${mac}.address}:"$1" elena
  '';
in {
  options.localModules.ssh = {
    enable = lib.mkEnableOption "ssh";
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "*".StrictHostKeyChecking = "no";

        "git.${secrets.domain}" = {
          Port = 2222;
          User = "git";
        };

        ${mac}.ProxyCommand = "${macProxy} %p";
      };
    };
  };
}
