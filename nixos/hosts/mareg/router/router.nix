{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: let
  wan = config.router.wanInterface;
  inherit (secrets.network.networks) lan guest iot;
  adguard = lib.head secrets.network.home.nameserversAdguard;

  # The drop-policy input chain must accept these: tailscale0 (else SSH over the
  # tailnet locks out) and podman* (else containers can't reach aardvark DNS /
  # host.containers.internal on their bridge gateway).
  inputAccept =
    lib.concatStringsSep ", " (map (i: ''"${i}"'')
      ["lo" "br-lan" "vlan20" "vlan40" "tailscale0" "podman*"]);

  iotDevices = secrets.network.iot.devices;
  # DHCP reservations (devices with an address) + the WAN egress allowlist
  # (allowWan); every other IoT device is blocked from the internet.
  iotReservations =
    lib.mapAttrsToList
    (mac: d: lib.concatStringsSep "," ([mac] ++ lib.optional (d ? name) d.name ++ [d.address]))
    (lib.filterAttrs (_: d: d ? address) iotDevices);
  iotWanAllow =
    lib.concatStringsSep ", "
    (lib.attrNames (lib.filterAttrs (_: d: d.allowWan or false) iotDevices));
in {
  config = lib.mkIf config.router.enable {
    # The hand-written ruleset is authoritative; the default NixOS firewall
    # would add a second drop-policy input base chain that silently drops
    # DHCP/relay traffic before dnsmasq.
    networking.firewall.enable = false;

    networking.nftables = {
      enable = true;
      ruleset = ''
        table inet filter {
          chain input {
            type filter hook input priority 0;
            policy drop;

            iifname { ${inputAccept} } accept
            ct state established,related accept

            icmpv6 type {
              nd-router-solicit, nd-router-advert,
              nd-neighbor-solicit, nd-neighbor-advert,
              mld-listener-query, mld-listener-report, mld-listener-done
            } accept

            iifname "${wan}" ip6 saddr fe80::/10 icmpv6 type { 130, 131, 132, 143 } accept
            iifname "${wan}" udp dport 546 ip6 saddr fc00::/6 accept
            iifname "${wan}" udp dport 41641 accept
            # DS-Lite decap: only the AFTR legitimately sends us IPv4-in-IPv6.
            iifname "${wan}" ip6 saddr ${config.router.dslite.aftr} ip6 nexthdr 4 accept
            iifname "${wan}" icmp type echo-request accept
            iifname "${wan}" icmpv6 type { echo-request, echo-reply, destination-unreachable, packet-too-big, time-exceeded } accept
          }

          chain forward {
            type filter hook forward priority 0;
            policy drop;

            # MSS clamp to path MTU so large TCP survives the 1460-byte
            # DS-Lite tunnel.
            oifname { "${wan}", "ds-wan" } tcp flags syn / syn,rst tcp option maxseg size set rt mtu

            ct state established,related accept

            # Tailscale subnet router: let tailnet clients reach internal
            # hosts (e.g. IoT/LAN devices that don't run tailscale).
            iifname "tailscale0" oifname { "br-lan", "vlan20", "vlan40" } accept

            # LAN and guest reach the internet unrestricted.
            iifname { "br-lan", "vlan20" } oifname { "${wan}", "ds-wan" } accept

            # Containers reach the internet AND internal hosts (MQTT broker,
            # frigate cameras on iot, syncthing peers over tailscale, LAN).
            iifname "podman*" accept

            # Published container ports reachable from LAN, IoT, tailscale, and
            # other containers (IoT -> MQTT broker, LAN -> netbootxyz TFTP,
            # tailnet -> forgejo SSH 2222): netavark DNATs the inbound to the
            # container bridge. Scoped by ingress iface so guest (vlan20) and
            # the WAN can't reach them.
            iifname { "br-lan", "vlan40", "tailscale0", "podman*" } ct status dnat oifname "podman*" accept

            # IoT egress allowlist, then deny the rest (no IoT->LAN/guest at all).
            iifname "vlan40" oifname { "${wan}", "ds-wan" } ether saddr { ${iotWanAllow} } accept
            iifname "vlan40" oifname { "${wan}", "ds-wan" } drop

            icmpv6 type { destination-unreachable, packet-too-big, time-exceeded } accept
          }
        }

        table ip nat {
          chain postrouting {
            type nat hook postrouting priority 100;
            policy accept;

            oifname { "${wan}", "ds-wan" } masquerade
            # Containers reaching tailscale peers need SNAT (the tailnet has no
            # route back to the podman subnet).
            oifname "tailscale0" ip saddr 10.88.0.0/15 masquerade
          }
        }
      '';
    };

    services.resolved.enable = false;

    # Proxy NDP the ISP /64 so LAN clients (SLAAC'd from it) are reachable
    # upstream. autowire is prefix-agnostic (survives a /64 rotation);
    # `iface br-lan` only proxies addresses a real br-lan neighbour answers.
    services.ndppd = {
      enable = true;
      configFile = pkgs.writeText "ndppd.conf" ''
        route-ttl 30000
        proxy ${wan} {
          router yes
          autowire yes
          timeout 500
          ttl 30000
          rule ::/0 {
            iface br-lan
          }
        }
      '';
    };

    # autowire shells out to `ip`, so iproute2 must be on PATH. And ndppd
    # exits (no retry) if vlan10 isn't bindable yet at boot — restart until up.
    systemd.services.ndppd = {
      path = [pkgs.iproute2];
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    services.dnsmasq = {
      enable = true;
      settings = {
        interface = [lan.interface guest.interface iot.interface];
        # bind-dynamic: bind sockets as the bridge/VLAN interfaces appear
        # instead of failing if networkd hasn't brought them up yet.
        bind-dynamic = true;
        # DNS on an alternate port: coredns owns :53 and forwards the .lan zone
        # here for the DHCP-aware hostnames. dnsmasq does no upstream resolution.
        # 5354, not 5353 (mDNS), to avoid clashing with home-assistant zeroconf.
        port = 5354;
        local = "/lan/";
        domain = "lan";
        expand-hosts = true;
        no-resolv = true;
        dhcp-authoritative = true;
        enable-ra = true;
        dhcp-range = [
          "set:lan,${lan.prefix}.100,${lan.prefix}.249,12h"
          "set:guest,${guest.prefix}.100,${guest.prefix}.249,12h"
          "set:iot,${iot.prefix}.100,${iot.prefix}.249,12h"
          "::,constructor:${lan.interface},ra-stateless"
        ];
        dhcp-option = [
          # Don't advertise ourselves as the IPv6 DNS server (RDNSS), or
          # dual-stack clients use the router for DNS and bypass AdGuard's
          # split-horizon + filtering.
          "option6:dns-server"
          # LAN DNS = coredns -> AdGuard on this router.
          "tag:lan,3,${lan.prefix}.1"
          "tag:lan,6,${adguard}"
          "tag:lan,42,${lan.prefix}.1"
          "tag:guest,3,${guest.prefix}.1"
          "tag:guest,6,1.1.1.1"
          "tag:guest,42,${guest.prefix}.1"
          "tag:iot,3,${iot.prefix}.1"
          "tag:iot,6,1.1.1.1"
          "tag:iot,42,${iot.prefix}.1"
        ];
        dhcp-host = iotReservations;
      };
    };
  };
}
