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
  macOnline = pkgs.writeShellScript "${mac}-online" ''
    tailscale status --json 2>/dev/null \
      | ${lib.getExe pkgs.jq} -e --arg ip ${macTailscaleIp} \
        '.Peer[] | select(.TailscaleIPs | index($ip)) | .Online' >/dev/null
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

        "${mac}-tailscale" = lib.hm.dag.entryBefore [mac] {
          header = ''Match originalhost ${mac} exec "${macOnline}"'';
          HostName = macTailscaleIp;
          ProxyJump = "none";
        };

        # A sleeping Mac is offline on the tailnet, but a connection to its LAN
        # address wakes it through the Bonjour sleep proxy.
        ${mac} = {
          HostName = secrets.network.home.hosts.${mac}.address;
          ProxyJump = "elena";
        };
      };
    };
  };
}
