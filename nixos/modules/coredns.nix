{
  config,
  pkgs,
  lib,
  secrets,
  localLib,
  self,
  ...
}: let
  cfg = config.localModules.coredns;
in {
  options.localModules.coredns = {
    enable = lib.mkEnableOption "coredns";

    domain = lib.mkOption {
      type = lib.types.str;
      default = secrets.domain;
      description = ''
        The domain name.
      '';
    };

    upstreamDns = lib.mkOption {
      type = lib.types.str;
      description = ''
        DNS server to forward requests to.
      '';
    };

    enableLan = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Serve home LAN hosts to local network.
      '';
    };

    additionalBindInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        Additional interfaces, besides tailscale0 and lo, to listen on.
      '';
    };

    lanDnsServer = lib.mkOption {
      type = lib.types.str;
      default = "10.0.0.1";
      description = ''
        Where to forward the .lan zone (the router's DHCP-aware DNS). Co-located
        with coredns on the router, point this at dnsmasq's alternate port.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.coredns = let
      dnsNames = localLib.dnsNamesByHost cfg.domain self.nixosConfigurations;
      machinesLan = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (n: v: "${secrets.network.home.hosts.${n}.address} ${n}.lan")
        secrets.network.home.hosts
      );
      hostsTailscale = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (n: fqdns:
          secrets.network.tailscale.hosts.${n}.address + " " + (lib.concatStringsSep " " fqdns))
        (lib.filterAttrs (n: v: builtins.hasAttr n secrets.network.tailscale.hosts) dnsNames)
      );
      hostsLan = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (n: fqdns:
          secrets.network.home.hosts.${n}.address + " " + (lib.concatStringsSep " " fqdns))
        (lib.filterAttrs (n: v: builtins.hasAttr n secrets.network.home.hosts) dnsNames)
      );
    in {
      enable = true;
      config = ''
        . {
          bind ${secrets.network.tailscale.hosts.${config.networking.hostName}.address}
          hosts {
            ${machinesLan}
            ${hostsTailscale}
            fallthrough
          }
          rewrite name regex (.*\.)?(.*)\.ts\.${lib.escapeRegex cfg.domain} {2}.${secrets.terranix.tailscale.tailnetName} answer auto
          rewrite name regex (.*\.)?(.*)\.lan\.${lib.escapeRegex cfg.domain} {2}.lan answer auto
          forward ${secrets.terranix.tailscale.tailnetName} 100.100.100.100
          forward lan ${cfg.lanDnsServer}
          forward . ${cfg.upstreamDns}
          errors
          cache
        }

        . {
          bind lo ${lib.concatStringsSep " " cfg.additionalBindInterfaces}
          hosts {
            ${machinesLan}
            ${
          if cfg.enableLan
          then hostsLan
          else hostsTailscale
        }
            fallthrough
          }
          rewrite name regex (.*\.)?(.*)\.ts\.${lib.escapeRegex cfg.domain} {2}.${secrets.terranix.tailscale.tailnetName} answer auto
          rewrite name regex (.*\.)?(.*)\.lan\.${lib.escapeRegex cfg.domain} {2}.lan answer auto
          forward ${secrets.terranix.tailscale.tailnetName} 100.100.100.100
          forward lan ${cfg.lanDnsServer}
          forward . ${cfg.upstreamDns}
          errors
          cache
        }
      '';
    };

    # TailScale address is not available on boot
    # ref: https://github.com/tailscale/tailscale/issues/11504
    systemd.services.coredns = {
      # TODO: Tailscale wait: https://github.com/tailscale/tailscale/pull/18574
      preStart = ''
        until ${lib.getExe' pkgs.iproute2 "ip"} -4 -json addr show tailscale0 | ${lib.getExe pkgs.jq} -e '. != []'; do
          sleep 1
        done
      '';
      after = ["tailscale.service"];
    };
  };
}
