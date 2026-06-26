{
  config,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules.home-router;
  inherit (secrets.network.networks) lan guest iot;

  # Untagged VLAN 1 (LAN) + tagged 10/20/40, on both the trunk port and br-lan
  # itself so the bridge hands the tagged VLANs up to the vlanNN netdevs.
  trunkVLANs = [
    {
      PVID = 1;
      EgressUntagged = 1;
    }
    {VLAN = 10;}
    {VLAN = 20;}
    {VLAN = 40;}
  ];
in {
  config = lib.mkIf config.localModules.home-router.enable {
    networking.useNetworkd = true;
    networking.useDHCP = false;

    systemd.network = {
      enable = true;

      # MAC-based persistent naming so the single integrated NIC keeps a
      # stable name (enx<mac>) for the trunk match.
      links."11-default" = {
        matchConfig.OriginalName = "*";
        linkConfig = {
          NamePolicy = "mac";
          MACAddressPolicy = "persistent";
        };
      };

      config.networkConfig = {
        IPv4Forwarding = true;
        IPv6Forwarding = true;
      };

      # VLANFiltering is mandatory: a plain bridge swallows tagged frames
      # before the vlanNN netdevs see them — incl. vlan10 (WAN), which must
      # ride the bridge since the single NIC is itself a bridge port.
      netdevs.br-lan = {
        netdevConfig = {
          Name = lan.interface;
          Kind = "bridge";
          MACAddress = cfg.macAddress;
        };
        bridgeConfig = {
          VLANFiltering = true;
          DefaultPVID = 1;
          STP = false;
        };
      };

      netdevs.vlan10 = {
        netdevConfig = {
          Name = cfg.wanInterface;
          Kind = "vlan";
        };
        vlanConfig.Id = 10;
      };
      netdevs.vlan20 = {
        netdevConfig = {
          Name = guest.interface;
          Kind = "vlan";
        };
        vlanConfig.Id = 20;
      };
      netdevs.vlan40 = {
        netdevConfig = {
          Name = iot.interface;
          Kind = "vlan";
        };
        vlanConfig.Id = 40;
      };

      networks = {
        "20-lan-trunk" = {
          matchConfig.Name = cfg.interface;
          networkConfig.Bridge = lan.interface;
          bridgeVLANs = trunkVLANs;
        };

        # br-lan itself = LAN (VLAN 1) + parent of the vlanNN netdevs. Host's
        # own fixed address; the .1 gateway is a keepalived VIP (keepalived.nix).
        # No static IPv6 /64 here — lan-prefix + dnsmasq + ndppd handle v6.
        "30-br-lan" = {
          matchConfig.Name = lan.interface;
          address = ["${secrets.network.home.hosts.${config.networking.hostName}.address}/24"];
          vlan = [cfg.wanInterface guest.interface iot.interface];
          networkConfig = {
            IPv4Forwarding = true;
            IPv6Forwarding = true;
          };
          bridgeVLANs = trunkVLANs;
        };

        # .1 gateways are keepalived VIPs (keepalived.nix), not static here.
        "31-guest" = {
          matchConfig.Name = guest.interface;
          networkConfig.IPv4Forwarding = true;
        };

        "32-iot" = {
          matchConfig.Name = iot.interface;
          networkConfig.IPv4Forwarding = true;
        };

        # WAN = tagged VLAN 10. DHCPv6 + accept-RA for the ISP IPoE /64;
        # don't install the on-link /64 here (ndppd proxies it to LAN).
        "40-wan" = {
          matchConfig.Name = cfg.wanInterface;
          networkConfig = {
            DHCP = "ipv6";
            IPv6AcceptRA = true;
          };
          ipv6AcceptRAConfig.UseOnLinkPrefix = false;
          linkConfig.RequiredForOnline = "no";
        };
      };
    };
  };
}
