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

    uplinks = lib.mkOption {
      type = lib.types.nonEmptyListOf lib.types.str;
      description = "Permanent MACs of the NICs bonded active-backup into br0; the first is used whenever it has link.";
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
      nameservers = lib.mkDefault [secrets.network.home.nameserver];
    };

    systemd.network = lib.mkMerge [
      {
        netdevs.bond0 = {
          netdevConfig = {
            Kind = "bond";
            Name = "bond0";
          };
          bondConfig = {
            Mode = "active-backup";
            MIIMonitorSec = "100ms";
            PrimaryReselectPolicy = "always";
          };
        };

        networks.bond0 = {
          matchConfig.Name = "bond0";
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
            # Explicit: the default turns RAs off whenever forwarding is on.
            IPv6AcceptRA = true;
            IPv6PrivacyExtensions = "kernel";
            Address = "${cfg.address}/24";
            # Per-link so it survives the tailscale module's global
            # 100.100.100.100, which is dead (and blocks re-auth) while
            # tailscale is logged out.
            DNS = secrets.network.home.nameserver;
            VLAN = lib.optional cfg.iotNetwork.enable "vlan40";
          };
          routes = [
            {Gateway = secrets.network.home.defaultGateway;}
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

        networks.vlan40 = lib.mkIf cfg.iotNetwork.enable {
          matchConfig.Name = "vlan40";
          networkConfig = {
            DHCP = "no";
            IPv6PrivacyExtensions = "kernel";
            Address = "${cfg.iotNetwork.address}/24";
          };
        };
      }
      {
        # br0 decides when the host is online, so a dead or unplugged uplink
        # doesn't hold up boot.
        networks = lib.listToAttrs (lib.imap0 (i: mac:
          lib.nameValuePair "uplink${toString i}" {
            matchConfig.PermanentMACAddress = mac;
            networkConfig = {
              Bond = "bond0";
              PrimarySlave = i == 0;
            };
            linkConfig.RequiredForOnline = "no";
          })
        cfg.uplinks);
      }
    ];
  };
}
