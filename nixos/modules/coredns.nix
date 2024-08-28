{
  config,
  pkgs,
  lib,
  secrets,
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
      default = secrets.domain;
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
  };

  config = lib.mkIf cfg.enable {
    services.coredns = let
      machinesLan = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (n: v: "${secrets.network.home.hosts.${n}.address} ${n}.lan")
        secrets.network.home.hosts
      );
      hostsTailscale = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (n: v:
          secrets.network.tailscale.hosts.${n}.address + " " + (lib.concatStringsSep " " (builtins.map (n: "${n}.${cfg.domain}") v.subdomains)))
        (lib.filterAttrs (n: v: builtins.hasAttr n secrets.network.tailscale.hosts) secrets.terranix.servers)
      );
      hostsLan = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (n: v:
          secrets.network.home.hosts.${n}.address + " " + (lib.concatStringsSep " " (builtins.map (n: "${n}.${cfg.domain}") v.subdomains)))
        (lib.filterAttrs (n: v: builtins.hasAttr n secrets.network.home.hosts) secrets.terranix.servers)
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
          forward lan 10.0.0.1
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
          forward lan 10.0.0.1
          forward . ${cfg.upstreamDns}
          errors
          cache
        }
      '';
    };

    # TailScale address is not available on boot
    # ref: https://github.com/tailscale/tailscale/issues/11504
    systemd.services.coredns = {
      preStart = ''
        until ${lib.getExe' pkgs.iproute2 "ip"} -4 -json addr show tailscale0 | ${lib.getExe pkgs.jq} -e '. != []'; do
          sleep 1
        done
      '';
      after = ["tailscale.service"];
    };
  };
}
