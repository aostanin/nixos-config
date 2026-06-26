{
  config,
  lib,
  ...
}: {
  imports = [
    ./dns.nix
    ./dslite.nix
    ./keepalived.nix
    ./lan-prefix.nix
    ./network.nix
    ./ntp.nix
    ./router.nix
  ];

  options.localModules.home-router = {
    enable = lib.mkEnableOption "native home router";

    interface = lib.mkOption {
      type = lib.types.str;
      description = "LAN trunk port (untagged LAN, tagged guest/iot).";
    };

    macAddress = lib.mkOption {
      type = lib.types.str;
      description = "MAC address for the LAN bridge.";
    };

    wanInterface = lib.mkOption {
      type = lib.types.str;
      default = "vlan10";
      internal = true;
      readOnly = true;
      description = "WAN uplink interface.";
    };
  };

  config = lib.mkIf config.localModules.home-router.enable {
    assertions = [
      {
        assertion = !config.localModules.home-server.enable;
        message = "localModules.home-router.enable and localModules.home-server both drive systemd-networkd; enable only one.";
      }
    ];
  };
}
