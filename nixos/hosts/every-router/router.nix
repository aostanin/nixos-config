{config, ...}: {
  networking.nftables = {
    enable = true;
    ruleset = ''
      table inet filter {
        chain input {
          type filter hook input priority 0;
          policy drop;

          iifname { "lo", "br-lan", "tailscale0" } accept
          ct state established,related accept

          icmpv6 type { nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } accept
        }

        chain forward {
          type filter hook forward priority 0;
          policy drop;

          iifname "br-lan" oifname { "end1", "wwu1i4" } accept
          ct state established,related accept
        }
      }

      table ip nat {
        chain postrouting {
          type nat hook postrouting priority 100;
          policy accept;

          oifname { "end1", "wwu1i4" } masquerade
        }
      }
    '';
  };

  services.resolved.enable = false;

  services.dnsmasq = {
    enable = true;
    settings = {
      interface = "br-lan";
      domain-needed = true;
      bogus-priv = true;
      dhcp-range = "10.0.50.100,10.0.50.200,12h";
      dhcp-option = [
        "3,10.0.50.1" # Default gateway
        "6,10.0.50.1" # DNS server
      ];
      local = "/lan/";
      domain = "lan";
      expand-hosts = true;
      no-resolv = true;
      # Use Tailscale DNS first, otherwise fallback to public DNS servers
      strict-order = true;
      server =
        (
          if config.services.tailscale.enable
          then ["100.100.100.100"]
          else []
        )
        ++ ["1.1.1.1" "8.8.8.8"];
    };
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    allowInterfaces = ["br-lan"];
  };
}
