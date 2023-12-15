{
  lib,
  pkgs,
  config,
  secrets,
  ...
}:
with lib; let
  cfg = config.localModules.home-server;

  networkSubmodule = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      address = mkOption {
        type = types.str;
      };
    };
  };
in {
  options.localModules.home-server = {
    enable = mkEnableOption "home-server";

    interface = mkOption {
      type = types.str;
    };

    address = mkOption {
      type = types.str;
    };

    macAddress = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    iotNetwork = mkOption {
      type = networkSubmodule;
      default = {};
    };

    storageNetwork = mkOption {
      type = networkSubmodule;
      default = {};
    };
  };

  config = mkIf cfg.enable {
    systemd.network.links."11-default" = {
      matchConfig.OriginalName = "*";
      linkConfig.NamePolicy = "mac";
      linkConfig.MACAddressPolicy = "persistent";
    };

    networking = {
      vlans.vlan40 = mkIf cfg.iotNetwork.enable {
        id = 40;
        interface = "br0";
      };

      vlans.vlan50 = mkIf cfg.storageNetwork.enable {
        id = 50;
        interface = "br0";
      };

      bridges.br0.interfaces = [cfg.interface];
      interfaces.br0 = {
        macAddress = mkIf (cfg.macAddress != null) cfg.macAddress;
        ipv4.addresses = [
          {
            address = cfg.address;
            prefixLength = 24;
          }
        ];
      };

      interfaces.vlan40 = mkIf cfg.iotNetwork.enable {
        ipv4.addresses = [
          {
            address = cfg.iotNetwork.address;
            prefixLength = 24;
          }
        ];
      };

      interfaces.vlan50 = mkIf cfg.storageNetwork.enable {
        ipv4.addresses = [
          {
            address = cfg.storageNetwork.address;
            prefixLength = 24;
          }
        ];
      };

      defaultGateway = {
        address = secrets.network.home.defaultGateway;
        interface = "br0";
      };
      nameservers = secrets.network.home.nameserversAdguard;
    };
  };
}
