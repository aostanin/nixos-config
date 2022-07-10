{ config, pkgs, lib, hardwareModulesPath, ... }:
let
  secrets = import ../../secrets;
  iface = "enp1s0";
  iface_lan = "enp7s0";
in
{
  imports = [
    "${hardwareModulesPath}/common/cpu/intel"
    "${hardwareModulesPath}/common/pc/ssd"
    ./hardware-configuration.nix
    ../../modules/variables
    ../../modules/common
    ../../modules/zerotier
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };
    kernelParams = [
      # For virsh console
      "console=ttyS0,115200"
      "console=tty1"
    ];
  };

  systemd.package = pkgs.systemd.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      # network: tunnel: automatic local address selection
      # ref: https://github.com/systemd/systemd/pull/21648
      ./patches/systemd-21648.patch
    ];
  });

  networking = {
    hostName = "router";

    nameservers = [
      "8.8.8.8"
      "8.8.4.4"
    ];

    useNetworkd = true;
    useDHCP = false;

    vlans = {
      wan6 = { id = 10; interface = iface; };
      # guest = { id = 20; interface = iface; };
      # iot = { id = 40; interface = iface; };
    };

    # TODO: Switch to iface once ready
    # bridges.lan.interfaces = [ iface ];
    bridges.lan.interfaces = [ iface_lan ];
    interfaces.lan = {
      ipv4.addresses = [{
        address = "10.0.0.1";
        prefixLength = 24;
      }];
    };

    # interfaces.guest = {
    #   ipv4.addresses = [{
    #     address = "10.0.20.1";
    #     prefixLength = 24;
    #   }];
    # };

    # interfaces.iot = {
    #   ipv4.addresses = [{
    #     address = "10.0.40.1";
    #     prefixLength = 24;
    #   }];
    # };
  };

  systemd.network = {
    netdevs.wan_dslite = {
      netdevConfig = {
        Name = "wan_dslite";
        Kind = "ip6tnl";
      };
      tunnelConfig = {
        Mode = "ipip6";
        Remote = "2404:8e00::feed:100";
        Local = "slaac";
      };
    };

    networks.wan_dslite = {
      matchConfig.Name = "wan_dslite";
      networkConfig = {
        IPForward = "ipv4";
        Address = "192.0.0.2";
        LinkLocalAddressing = "no";
      };
      routes = [
        { routeConfig = { Destination = "0.0.0.0/0"; }; }
      ];
    };

    networks.wan6 = {
      matchConfig.Name = "wan6";
      networkConfig = {
        Tunnel = "wan_dslite";
        IPv6AcceptRA = "yes";
      };
    };
  };

  services.pppd = {
    # TODO: Use as fallback?
    # enable = true;
    peers.iij = {
      autostart = true;
      enable = true;
      config = ''
        plugin rp-pppoe.so wan6

        name "${secrets.pppoe.username}"
        password "${secrets.pppoe.password}"

        persist
        maxfail 0
        holdoff 5

        noipdefault
        #defaultroute
      '';
    };
  };

  services.dnsmasq = {
    enable = true;
    servers = [
      "8.8.8.8"
      "8.8.4.4"
    ];
    extraConfig = ''
      dhcp-authoritative
      domain-needed
      localise-queries
      expand-hosts
      domain=lan
      stop-dns-rebind
      rebind-localhost-ok
      bogus-priv

      interface=lan
      interface=guest
      interface=iot

      dhcp-range=set:lan,10.0.0.100,10.0.0.254,24h
      dhcp-range=set:guest,10.0.20.100,10.0.20.254,24h
      dhcp-range=set:iot,10.0.40.100,10.0.40.254,24h

      # TODO: Set up AdGuard Home
      dhcp-option=tag:lan,option:dns-server,10.0.0.10

      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (hostname: lease:
        "dhcp-host=${lease.macAddress},${lease.ipAddress},${hostname}"
      ) secrets.leases)}
    '';
  };
  services.resolved.enable = false;

  services.ndppd = {
    # TODO: Not working for now
    # enable = true;
    # configFile = pkgs.writeText "ndppd.conf" ''
    #   proxy wan6 {
    #     router no
    #     timeout 500
    #     autowire yes
    #     keepalive yes
    #     retries 3
    #     ttl 30000
    #     rule ::/0 {
    #       iface lan
    #     }
    #   }

    #   proxy lan {
    #     router yes
    #     timeout 500
    #     autowire yes
    #     keepalive yes
    #     retries 3
    #     ttl 30000
    #     rule ::/0 {
    #       iface wan6
    #     }
    #   }
    # '';
    proxies = {
      wan6 = {
        router = false;
        rules."::/0" = {
          method = "iface";
          interface = "lan";
        };
      };
      lan = {
        router = true;
        rules."::/0" = {
          method = "iface";
          interface = "wan6";
        };
      };
    };
  };

  networking.nftables = {
    enable = true;
    ruleset = ''
      # ref: https://wiki.gentoo.org/wiki/Nftables/Examples

      table ip filter {
        # allow all packets sent by the firewall machine itself
        chain output {
          type filter hook output priority 100; policy accept;
        }

        # allow LAN to firewall, disallow WAN to firewall
        chain input {
          type filter hook input priority 0; policy accept;
          iifname "lan0" accept
          iifname "wan0" drop
        }

        # allow packets from LAN to WAN, and WAN to LAN if LAN initiated the connection
        chain forward {
          type filter hook forward priority 0; policy drop;
          iifname "lan0" oifname "wan0" accept
          iifname "wan0" oifname "lan0" ct state related,established accept
        }
      }
    '';
  };
}
