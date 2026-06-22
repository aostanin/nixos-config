{
  config,
  lib,
  secrets,
  ...
}: {
  # Serve NTP to the LAN (DHCP option 42 points clients here). chrony answers
  # only the LAN subnets; the WAN input chain drops udp/123 anyway.
  config = lib.mkIf config.router.enable {
    services.chrony = {
      enable = true;
      extraConfig =
        lib.concatMapStringsSep "\n"
        (n: "allow ${n.prefix}.0/24")
        (lib.attrValues secrets.network.networks);
    };
  };
}
