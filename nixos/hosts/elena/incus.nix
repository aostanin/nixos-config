{secrets, ...}: {
  virtualisation.incus = {
    enable = true;
    preseed = {
      networks = [
        {
          name = "incusbr0";
          type = "bridge";
          # NAT and filtering live in the router's nftables ruleset: its full
          # reload would flush the table Incus manages.
          config = {
            "ipv4.address" = "10.90.0.1/24";
            "ipv4.nat" = "false";
            "ipv4.firewall" = "false";
            "ipv6.address" = "none";
          };
        }
      ];
      storage_pools = [
        {
          name = "default";
          driver = "zfs";
          config.source = "rpool/virtualization/incus";
        }
      ];
      profiles = [
        {
          name = "default";
          devices = {
            eth0 = {
              name = "eth0";
              network = "incusbr0";
              type = "nic";
            };
            root = {
              path = "/";
              pool = "default";
              type = "disk";
            };
          };
        }
      ];
    };
  };

  users.users.${secrets.user.username}.extraGroups = ["incus-admin"];
}
