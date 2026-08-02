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
      default = "tls://${secrets.filteringDns.ipv4}%${secrets.filteringDns.hostname}";
      description = ''
        Default upstream for the trusted (lan/tailscale) views — DoT to Mullvad
        adblock (filtered + encrypted), from secrets. Any CoreDNS forward TO syntax.
      '';
    };

    allowlist = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = secrets.dnsAllowlist;
      description = ''
        Domains exempted from filtering — forwarded to allowlistUpstream instead
        of the filtered upstream. Ports the AdGuard @@ user_rules to the LAN path.
      '';
    };

    allowlistUpstream = lib.mkOption {
      type = lib.types.str;
      default = "tls://1.1.1.1%cloudflare-dns.com";
      description = "Unfiltered upstream for allowlist domains.";
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

      # Per-domain forwards to an unfiltered upstream, exempting allowlist domains
      # from the filtered default (more-specific zone wins).
      allowlistForwards =
        lib.concatMapStringsSep "\n  "
        (d: "forward ${d} ${cfg.allowlistUpstream}")
        cfg.allowlist;

      # localhost rides this host's identity (LAN if a LAN host, else tailscale).
      # Must match ::1 too — bind/glibc query the v6 loopback, which else fell
      # through to the public catch-all (Cloudflare tunnel IP).
      loopback = "incidr(client_ip(), '127.0.0.0/8') || incidr(client_ip(), '::1/128')";
      # Tailscale's v4 CGNAT range plus its fixed v6 ULA prefix — coredns binds
      # tailscale0's v6 address too, and a v6-sourced query matched no view, so
      # it fell through to the public catch-all (Cloudflare tunnel IP).
      tsExpr =
        "incidr(client_ip(), '100.64.0.0/10') || incidr(client_ip(), 'fd7a:115c:a1e0::/48')"
        + lib.optionalString (!cfg.enableLan) " || ${loopback}";
      lanExpr = "incidr(client_ip(), '${lan.prefix}.0/24') || ${loopback}";
      untrustedExpr =
        lib.concatMapStringsSep " || "
        (s: "incidr(client_ip(), '${s}')")
        cfg.untrustedSubnets;

      # Trusted view: internal names + split-horizon hosts, everything else to
      # the filtered upstream.
      internal = name: expr: hosts: ''
        .:53 {
          ${bindLine}
          view ${name} {
            expr ${expr}
          }
          hosts {
            ${hosts}
            fallthrough
          }
          rewrite name regex (.*\.)?(.*)\.ts\.${dom} {2}.${tailnet} answer auto
          # These names resolve to the internal Traefik, which can't do ECH. The
          # hosts plugin falls through on type 65, so the public HTTPS record
          # (ech=, public_name cloudflare-ech.com) would reach internal clients
          # and Firefox then fails the handshake against TRAEFIK DEFAULT CERT.
          template ANY HTTPS ${cfg.domain} {
            rcode NOERROR
          }
          forward ${tailnet} 100.100.100.100
          ${allowlistForwards}
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
