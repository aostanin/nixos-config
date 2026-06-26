{
  config,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules.home-router;
  inherit (secrets.network.networks) lan guest iot;
in {
  config = lib.mkIf cfg.enable {
    localModules.coredns = {
      enable = lib.mkDefault true;
      enableLan = lib.mkDefault true;
      upstreamDns = lib.mkDefault "127.0.0.1:5300";
      bindInterfaces = lib.mkDefault [
        "lo"
        "${lan.prefix}.1"
        "${guest.prefix}.1"
        "${iot.prefix}.1"
        "tailscale0"
      ];
      untrustedSubnets = lib.mkDefault [
        "${guest.prefix}.0/24"
        "${iot.prefix}.0/24"
      ];
      lanDnsServer = lib.mkDefault "${lan.prefix}.1:5354";
    };
    localModules.adguardhome.enable = lib.mkDefault true;
  };
}
