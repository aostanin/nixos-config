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
  inherit (secrets.network.networks) lan;
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

    bindInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["lo" "tailscale0"];
      description = ''
        Interfaces to bind to. CoreDNS can't bind 0.0.0.0 here (podman's
        aardvark-dns owns :53 on the container bridges), so enumerate the
        wanted interfaces and omit podman. The view plugin still does
        split-horizon by source IP regardless of which interface a query
        arrives on. All blocks share this bind (same-port rule).
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

    untrustedSubnets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        Source subnets (guest/iot) served public-forward-only — no internal
        names, no split-horizon.
      '';
    };

    publicUpstreams = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["1.1.1.1" "8.8.8.8"];
      description = ''
        Upstreams for the untrusted (guest/iot) and default views.
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

      tailnet = secrets.terranix.tailscale.tailnetName;
      dom = lib.escapeRegex cfg.domain;
      bindLine = "bind ${lib.concatStringsSep " " cfg.bindInterfaces}";

      # localhost rides this host's identity (LAN if a LAN host, else tailscale).
      # Must match ::1 too — bind/glibc query the v6 loopback, which else fell
      # through to the public catch-all (Cloudflare tunnel IP).
      loopback = "incidr(client_ip(), '127.0.0.0/8') || incidr(client_ip(), '::1/128')";
      tsExpr =
        "incidr(client_ip(), '100.64.0.0/10')"
        + lib.optionalString (!cfg.enableLan) " || ${loopback}";
      lanExpr = "incidr(client_ip(), '${lan.prefix}.0/24') || ${loopback}";
      untrustedExpr =
        lib.concatMapStringsSep " || "
        (s: "incidr(client_ip(), '${s}')")
        cfg.untrustedSubnets;

      # Trusted view: internal names + split-horizon hosts, then .lan to dnsmasq
      # and everything else to the filtered upstream.
      internal = name: expr: hosts: ''
        .:53 {
          ${bindLine}
          view ${name} {
            expr ${expr}
          }
          hosts {
            ${machinesLan}
            ${hosts}
            fallthrough
          }
          rewrite name regex (.*\.)?(.*)\.ts\.${dom} {2}.${tailnet} answer auto
          rewrite name regex (.*\.)?(.*)\.lan\.${dom} {2}.lan answer auto
          forward ${tailnet} 100.100.100.100
          forward lan ${cfg.lanDnsServer}
          forward . ${cfg.upstreamDns}
          errors
          cache
        }
      '';

      # Public-forward only: no internal names. `expr == null` = viewless
      # catch-all (anything not matched by a trusted/untrusted view).
      public = expr: ''
        .:53 {
          ${bindLine}
          ${lib.optionalString (expr != null) ''
          view untrusted {
            expr ${expr}
          }''}
          forward . ${lib.concatStringsSep " " cfg.publicUpstreams}
          errors
          cache
        }
      '';

      blocks =
        [(internal "tailscale" tsExpr hostsTailscale)]
        ++ lib.optional cfg.enableLan (internal "lan" lanExpr hostsLan)
        ++ lib.optional (cfg.untrustedSubnets != []) (public untrustedExpr)
        ++ [(public null)];
    in {
      enable = true;
      config = lib.concatStringsSep "\n" blocks;
    };

    # Interface-bind grabs addresses at start (SIGHUP won't re-bind), so restart
    # coredns once tailscale has an IP. VIPs are covered by ip_nonlocal_bind.
    systemd.services.coredns-rebind = lib.mkIf (lib.elem "tailscale0" cfg.bindInterfaces) {
      description = "Re-bind coredns once tailscale is up";
      wantedBy = ["multi-user.target"];
      after = ["coredns.service" "tailscaled.service"];
      wants = ["tailscaled.service"];
      path = [config.services.tailscale.package pkgs.systemd];
      serviceConfig.Type = "oneshot";
      script = ''
        tailscale wait
        systemctl try-restart coredns
      '';
    };
  };
}
