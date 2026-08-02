{
  config,
  lib,
  secrets,
  ...
}: {
  # Serve NTP to the LAN (DHCP option 42 points clients here). chrony answers
  # only the LAN subnets; the WAN input chain drops udp/123 anyway.
  config = lib.mkIf config.localModules.home-router.enable {
    services.chrony = {
      enable = true;
      # Hosts without a working RTC (pikvm) would otherwise boot with a weeks-old
      # clock; restore it from the driftfile mtime before the network comes up.
      extraFlags = ["-s"];
      extraConfig =
        ''
          # IP literals, because DNS forwards over DoT and DoT needs a valid clock:
          # hostname-only sources deadlock an RTC-less host after every reboot.
          server 133.243.238.163 iburst
          server 162.159.200.123 iburst
        ''
        + lib.concatMapStringsSep "\n"
        (n: "allow ${n.prefix}.0/24")
        (lib.attrValues secrets.network.networks);
    };
  };
}
