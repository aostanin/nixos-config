{secrets, ...}: let
  inherit (secrets.network.home) defaultGateway;
in {
  boot.isContainer = true;

  networking = {
    hostName = "dev";
    useHostResolvConf = false;
    interfaces.eth0.ipv4.addresses = [
      {
        inherit (secrets.network.home.hosts.dev) address;
        prefixLength = 24;
      }
    ];
    defaultGateway = {
      address = defaultGateway;
      interface = "eth0";
    };
    nameservers = [defaultGateway];
  };

  services.resolved.enable = true;

  localModules = {
    common = {
      enable = true;
      minimal = true;
    };
    nix-ld.enable = true;
  };

  # Swap and binfmt belong to the host.
  zramSwap.enable = false;

  roles.dev = {
    enable = true;
    publicHostname = "paseo.${secrets.domain}";
    appsHostname = "paseoapps.${secrets.domain}";
    # Traefik on elena.
    trustedProxies = ["loopback" secrets.network.home.hosts.elena.address];
  };
}
