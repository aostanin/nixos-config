{
  config,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules.dotClient;
in {
  options.localModules.dotClient = {
    enable = lib.mkEnableOption ''
      DNS-over-TLS to the filtered AdGuard endpoint via systemd-resolved. Strict
      (no fallback): if the endpoint is unreachable, DNS fails until it recovers,
      so captive portals need a manual `resolvectl` / DNS toggle to log in'';

    servers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = lib.concatMap (e: [
        "${e.ipv4}#${secrets.dns.hostname}"
        "${e.ipv6}#${secrets.dns.hostname}"
      ]) (lib.attrValues secrets.dns.endpoints);
      description = ''
        DoT servers as `IP#hostname` — the hostname is sent as SNI (matches the
        endpoint's HostSNI gate) and used for cert validation. Derived from the
        VPS endpoints in secrets (both VPSes, v4+v6).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.resolved = {
      enable = true;
      dnsovertls = "true";
    };

    # resolved global DNS = the DoT endpoint (overrides the tailscale module's
    # 100.100.100.100). Tailscale registers *.ostan.in on tailscale0 via resolved.
    networking.nameservers = lib.mkForce cfg.servers;

    # Keep NetworkManager from handing the DHCP resolver to resolved — otherwise
    # that link resolver wins for default queries and skips the DoT filter.
    networking.networkmanager.dns = lib.mkIf config.networking.networkmanager.enable (lib.mkForce "none");
  };
}
