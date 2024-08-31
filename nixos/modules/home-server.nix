{
  lib,
  pkgs,
  config,
  secrets,
  ...
}: let
  cfg = config.localModules.home-server;

  networkSubmodule = lib.types.submodule {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };

      address = lib.mkOption {
        type = lib.types.str;
      };
    };
  };
in {
  options.localModules.home-server = {
    enable = lib.mkEnableOption "home-server";

    interface = lib.mkOption {
      type = lib.types.str;
    };

    address = lib.mkOption {
      type = lib.types.str;
    };

    macAddress = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    iotNetwork = lib.mkOption {
      type = networkSubmodule;
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.network.links."11-default" = {
      matchConfig.OriginalName = "*";
      linkConfig.NamePolicy = "mac";
      linkConfig.MACAddressPolicy = "persistent";
    };

    networking = {
      vlans.vlan40 = lib.mkIf cfg.iotNetwork.enable {
        id = 40;
        interface = "br0";
      };

      bridges.br0.interfaces = [cfg.interface];
      interfaces.br0 = {
        macAddress = lib.mkIf (cfg.macAddress != null) cfg.macAddress;
        ipv4.addresses = [
          {
            address = cfg.address;
            prefixLength = 24;
          }
        ];
      };

      interfaces.vlan40 = lib.mkIf cfg.iotNetwork.enable {
        ipv4.addresses = [
          {
            address = cfg.iotNetwork.address;
            prefixLength = 24;
          }
        ];
      };

      defaultGateway = {
        address = secrets.network.home.defaultGateway;
        interface = "br0";
      };
      nameservers = lib.mkDefault secrets.network.home.nameserversAdguard;
    };
  };
}
