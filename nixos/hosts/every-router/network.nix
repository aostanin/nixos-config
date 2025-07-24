{...}: {
  networking.useNetworkd = true;

  systemd.network = {
    enable = true;

    config.networkConfig = {
      IPv4Forwarding = true;
    };

    networks.wan = {
      matchConfig.Name = "end1";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
      };
      dhcpV4Config.RouteMetric = 10;
      ipv6AcceptRAConfig.RouteMetric = 10;
      linkConfig.RequiredForOnline = "no";
    };

    netdevs.br-lan = {
      netdevConfig = {
        Name = "br-lan";
        Kind = "bridge";
      };
    };

    networks.end0 = {
      matchConfig.Name = "end0";
      networkConfig.Bridge = "br-lan";
    };

    networks.wlan0 = {
      matchConfig.Name = "wlan0";
      networkConfig.Bridge = "br-lan";
    };

    networks.wlan1 = {
      matchConfig.Name = "wlan1";
      networkConfig.Bridge = "br-lan";
    };

    networks.br-lan = {
      matchConfig.Name = "br-lan";
      address = ["10.0.50.1/24"];
      networkConfig = {
        IPv6SendRA = true;
        IPv4Forwarding = true;
      };
      ipv6Prefixes = [
        {
          Prefix = "fdf8:5779:959e::/64";
          Assign = true;
        }
      ];
    };
  };
}
