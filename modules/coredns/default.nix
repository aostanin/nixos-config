{
  config,
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
          view tailscale {
            expr incidr(client_ip(), '100.64.0.0/10')
          }
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
          log
          errors
          cache
        }

        . {
          hosts {
            ${machinesLan}
            ${hostsLan}
            fallthrough
          }
          rewrite name regex (.*\.)?(.*)\.ts\.${lib.escapeRegex cfg.domain} {2}.${secrets.terranix.tailscale.tailnetName} answer auto
          rewrite name regex (.*\.)?(.*)\.lan\.${lib.escapeRegex cfg.domain} {2}.lan answer auto
          forward ${secrets.terranix.tailscale.tailnetName} 100.100.100.100
          forward lan 10.0.0.1
          forward . ${cfg.upstreamDns}
          log
          errors
          cache
        }
      '';
    };
  };
}
