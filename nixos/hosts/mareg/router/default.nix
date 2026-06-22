{
  config,
  lib,
  ...
}: {
  imports = [
    ./network.nix
    ./router.nix
    ./dslite.nix
    ./lan-prefix.nix
    ./ntp.nix
  ];

  options.router = {
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

  config = lib.mkIf config.router.enable {
    assertions = [
      {
        assertion = !config.localModules.home-server.enable;
        message = "router.enable and localModules.home-server both drive systemd-networkd; enable only one.";
      }
    ];
  };
}
