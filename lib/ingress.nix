{lib, ...}: rec {
  trustedClientIps = [
    "100.64.0.0/10" # Tailscale
    "10.88.0.0/15" # Podman networks
    "10.0.0.0/24" # LAN
  ];

  # FQDNs for a service name. The bare `<name>.<domain>` form is included unless
  # `unqualified = false` (used for secondary instances that must not claim the
  # bare name); the `.lan`/`.ts` forms are host-scoped and never collide.
  mkHosts = {
    domain,
    host,
    name,
    unqualified ? true,
  }:
    lib.optional unqualified "${name}.${domain}"
    ++ [
      "${name}.${host}.lan.${domain}"
      "${name}.${host}.ts.${domain}"
    ];

  # An FQDN that needs an explicit DNS record: the apex `<domain>` or a direct
  # subdomain `<label>.<domain>`. Qualified `.lan`/`.ts` forms are served by
  # CoreDNS wildcards and excluded.
  isBareFqdn = domain: fqdn:
    fqdn
    == domain
    || (lib.hasSuffix ".${domain}" fqdn
      && !(lib.hasInfix "." (lib.removeSuffix ".${domain}" fqdn)));

  # The hostname running a given container service, discovered across all
  # hosts. Throws unless exactly one host enables it.
  hostRunningService = service: nixosConfigurations: let
    hosts = lib.attrNames (lib.filterAttrs (
        _: node: node.config.localModules.containers.services.${service}.enable or false
      )
      nixosConfigurations);
  in
    if lib.length hosts == 1
    then lib.head hosts
    else throw "expected exactly one host running ${service}, found: [${lib.concatStringsSep " " hosts}]";

  # Bare DNS names served by each host, derived from localModules.ingress across
  # all hosts and grouped by each entry's target host:
  #   { <host> = [ "name.domain" "domain" ... ]; }  (full FQDNs)
  # Throws on a name claimed by more than one host (conflicting records).
  dnsNamesByHost = domain: nixosConfigurations: let
    allEntries = lib.flatten (lib.mapAttrsToList (
        _: node:
          lib.mapAttrsToList (_: e: {inherit (e) host hosts enable;})
          (node.config.localModules.ingress or {})
      )
      nixosConfigurations);
    enabled = lib.filter (e: e.enable) allEntries;
    byHost = lib.groupBy (e: e.host) enabled;
    perHost =
      lib.mapAttrs (
        _: entries:
          lib.sort (a: b: a < b) (lib.unique (lib.filter (isBareFqdn domain)
              (lib.flatten (map (e: e.hosts) entries))))
      )
      byHost;

    nameOwners = lib.groupBy (x: x.name) (lib.flatten (lib.mapAttrsToList (
        host: names: map (name: {inherit host name;}) names
      )
      perHost));
    collisions = lib.filterAttrs (_: owners: lib.length owners > 1) nameOwners;
  in
    if collisions != {}
    then
      throw ("ingress DNS name collision (claimed by multiple hosts): "
        + lib.concatStringsSep ", " (lib.mapAttrsToList (
            name: owners: "${name} -> ${lib.concatStringsSep "+" (map (o: o.host) owners)}"
          )
          collisions))
    else perHost;
}
