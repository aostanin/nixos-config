{
  config,
  lib,
  pkgs,
  ...
}: let
  wan = config.localModules.home-router.wanInterface;
in {
  options.localModules.home-router.dslite = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the DS-Lite tunnel.";
    };
    aftr = lib.mkOption {
      type = lib.types.str;
      default = "2404:8e00::feed:101";
      description = "DS-Lite AFTR address.";
    };
  };

  config = lib.mkIf (config.localModules.home-router.enable && config.localModules.home-router.dslite.enable) {
    systemd.services.dslite-tunnel = {
      description = "DS-Lite (transix) ip6tnl tunnel to AFTR";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      path = [pkgs.iproute2 pkgs.gawk pkgs.coreutils];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      # Reconcile (not just create-once): rebuild the tunnel only when the
      # WAN's global /64 changes, so a WAN bounce or ISP /64 rotation
      # self-heals on the next timer tick instead of leaving a stale tunnel.
      script = ''
        set -eu
        WAN=${wan}
        AFTR=${config.localModules.home-router.dslite.aftr}
        LOCAL6=""
        for _ in $(seq 1 15); do
          LOCAL6=$(ip -6 -o addr show dev "$WAN" scope global -temporary 2>/dev/null \
            | awk '{print $4}' | cut -d/ -f1 | head -n1)
          [ -n "$LOCAL6" ] && break
          sleep 2
        done
        # No WAN address yet: leave any existing tunnel alone and let the
        # timer retry (don't fail the unit).
        [ -n "$LOCAL6" ] || { echo "no global IPv6 on $WAN yet"; exit 0; }

        CUR=$(ip -d -o link show ds-wan 2>/dev/null \
          | awk '{for (i = 1; i <= NF; i++) if ($i == "local") print $(i + 1)}')
        if [ "$CUR" != "$LOCAL6" ]; then
          ip link del ds-wan 2>/dev/null || true
          ip link add name ds-wan type ip6tnl mode ipip6 remote "$AFTR" local "$LOCAL6" encaplimit none
          ip link set ds-wan mtu 1460 up
          ip addr add 192.0.0.2/29 dev ds-wan 2>/dev/null || true
        fi
        ip route replace default dev ds-wan
      '';
      preStop = "${pkgs.iproute2}/bin/ip link del ds-wan 2>/dev/null || true";
    };

    systemd.timers.dslite-tunnel = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "20s";
        OnUnitActiveSec = "60s";
      };
    };
  };
}
