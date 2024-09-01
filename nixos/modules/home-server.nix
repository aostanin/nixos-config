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
    networking = {
      useNetworkd = true;
      nameservers = lib.mkDefault secrets.network.home.nameserversAdguard;
    };

    systemd.network = {
      links."11-default" = {
        matchConfig.OriginalName = "*";
        linkConfig.NamePolicy = "mac";
        linkConfig.MACAddressPolicy = "persistent";
      };

      networks.${cfg.interface} = {
        matchConfig.Name = cfg.interface;
        networkConfig = {
          DHCP = "no";
          IPv6AcceptRA = "no";
          LinkLocalAddressing = "no";
          IPv6PrivacyExtensions = "kernel";
          Bridge = "br0";
          # MACVLAN = "macvlan0";
        };
      };

      netdevs.br0 = {
        netdevConfig = {
          Kind = "bridge";
          Name = "br0";
          MACAddress = lib.mkIf (cfg.macAddress != null) cfg.macAddress;
        };
      };

      networks.br0 = {
        matchConfig.Name = "br0";
        networkConfig = {
          DHCP = "no";
          IPv6PrivacyExtensions = "kernel";
          Address = "${cfg.address}/24";
          VLAN = lib.optional cfg.iotNetwork.enable "vlan40";
        };
        routes = [
          {routeConfig.Gateway = secrets.network.home.defaultGateway;}
        ];
      };

      # TODO: Issues with IPv6 on home network when using MACVLAN
      # netdevs.macvlan0 = {
      #   netdevConfig = {
      #     Name = "macvlan0";
      #     Kind = "macvlan";
      #     MACAddress = lib.mkIf (cfg.macAddress != null) cfg.macAddress;
      #   };
      #   macvlanConfig.Mode = "bridge";
      # };

      # networks.macvlan0 = {
      #   matchConfig.Name = "macvlan0";
      #   networkConfig = {
      #     DHCP = "no";
      #     IPv6PrivacyExtensions = "kernel";
      #     Address = "${cfg.address}/24";
      #     VLAN = lib.optional cfg.iotNetwork.enable "vlan40";
      #   };
      #   routes = [
      #     {routeConfig.Gateway = secrets.network.home.defaultGateway;}
      #   ];
      # };

      netdevs.vlan40 = lib.mkIf cfg.iotNetwork.enable {
        netdevConfig = {
          Kind = "vlan";
          Name = "vlan40";
        };
        vlanConfig.Id = 40;
      };

      networks.vlan40 = {
        matchConfig.Name = "vlan40";
        networkConfig = {
          DHCP = "no";
          IPv6PrivacyExtensions = "kernel";
          Address = "${cfg.iotNetwork.address}/24";
        };
      };
    };
  };
}
