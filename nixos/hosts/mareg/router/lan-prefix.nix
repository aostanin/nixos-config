{
  config,
  lib,
  pkgs,
  ...
}: let
  wan = config.router.wanInterface;
in {
  config = lib.mkIf config.router.enable {
    # Mirror the WAN's current /64 onto br-lan as <prefix>::1/64 so dnsmasq can
    # RA it to the LAN (no plain-Linux daemon relays a non-PD on-link /64).
    # Idempotent + timer = survives a /64 rotation, no hardcoded prefix.
    systemd.services.lan-prefix = {
      description = "Mirror WAN /64 onto br-lan (LAN RA prefix source)";
      after = ["network-online.target" "dslite-tunnel.service"];
      wants = ["network-online.target"];
      path = [pkgs.iproute2 pkgs.gawk pkgs.coreutils pkgs.python3 pkgs.systemd];
      serviceConfig.Type = "oneshot";
      script = ''
        set -eu
        WAN=${wan}
        LAN=br-lan
        addr=$(ip -6 -o addr show dev "$WAN" scope global -temporary 2>/dev/null \
          | awk '{print $4}' | cut -d/ -f1 | head -n1)
        [ -n "$addr" ] || { echo "no WAN global /64 yet"; exit 0; }
        # Real IPv6 parser: a naive string split breaks on ::-compressed or
        # zero-hextet prefixes, and the WAN addr is noprefixroute so there's
        # no kernel /64 route to read instead.
        want=$(python3 -c "import ipaddress,sys; n=ipaddress.ip_network(sys.argv[1]+'/64',strict=False); print(str(n.network_address+1)+'/64')" "$addr") || { echo "bad WAN addr '$addr'"; exit 0; }
        cur=$(ip -6 -o addr show dev "$LAN" scope global 2>/dev/null \
          | awk '{print $4}' | head -n1)
        if [ "$cur" != "$want" ]; then
          [ -n "$cur" ] && ip -6 addr del "$cur" dev "$LAN" || true
          ip -6 addr add "$want" dev "$LAN"
          systemctl reload-or-restart dnsmasq || true
        fi
      '';
    };
    systemd.timers.lan-prefix = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "30s";
        OnUnitActiveSec = "60s";
      };
    };
  };
}
