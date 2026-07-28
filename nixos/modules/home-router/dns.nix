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
    };
  };
}
