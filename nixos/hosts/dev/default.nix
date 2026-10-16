{
  config,
  lib,
  self,
  secrets,
  ...
}: let
  inherit (secrets.network.home) defaultGateway;

  litellmCodingModels =
    lib.filter (m: !(lib.elem m.model_name ["ha-assist" "kokoro" "whisper"]))
    self.nixosConfigurations.elena.config.localModules.containers.services.litellm.models;
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

  # Agents run under the paseo system service, not a login session, so without
  # linger the user manager stops on logout and wipes the home-manager sops
  # secrets in /run/user.
  users.users.${secrets.user.username}.linger = true;

  # Profiles under ~ get their GC roots registered by the host's nix-daemon at
  # the same path on the host, where they resolve to the host's own home, so
  # the host's GC deletes this container's home-manager generations. The host
  # does scan its per-container copy of /nix/var/nix/profiles.
  systemd.tmpfiles.settings."10-user-profiles" = let
    inherit (secrets.user) username;
    home = "/home/${username}";
    userDir = {
      user = username;
      group = "users";
      mode = "0755";
    };
  in {
    "/nix/var/nix/profiles/per-user/${username}".d = userDir;
    "${home}/.local".d = userDir;
    "${home}/.local/state".d = userDir;
    "${home}/.local/state/nix".d = userDir;
    "${home}/.local/state/nix/profiles".L.argument = "/nix/var/nix/profiles/per-user/${username}";
  };

  nix = {
    # The store database is the host's, read-only in here. Users get
    # NIX_REMOTE=daemon from their environment, but root under sudo (deploys)
    # needs this.
    settings.store = "daemon";
    # The host's GC covers this container's profiles too.
    gc.automatic = lib.mkForce false;
  };

  localModules = {
    common = {
      enable = true;
      minimal = true;
    };
    nix-ld.enable = true;
    traefik.enable = true;

    # Paseo's web UI, plus its service proxy for workspace dev servers. Served
    # from here so it follows the container between hosts.
    ingress.paseo = {
      inherit (config.services.paseo) port;
      hosts = [
        config.roles.dev.publicHostname
        "*.${config.roles.dev.appsHostname}"
      ];
    };
  };

  roles.dev = {
    enable = true;
    publicHostname = "paseo.${secrets.domain}";
    appsHostname = "paseoapps.${secrets.domain}";
  };

  services.paseo.settings = {
    version = 1;
    daemon = {
      mcp.injectIntoAgents = true;
      browserTools.enabled = true;
      cors.allowedOrigins = ["https://app.paseo.sh"];
    };
    agents.providers = {
      codex.enabled = false;
      copilot.enabled = false;
      opencode.enabled = false;
      # Provider config comes from home-manager's ~/.config/maki.
      maki = {
        extends = "acp";
        label = "Maki";
        command = ["maki" "acp" "--yolo"];
        # maki only reports its discovered models once a session is running, too
        # late for Paseo's model picker.
        additionalModels =
          map (m: {
            id = "elena/${m.model_name}";
            label = m.model_name;
          })
          litellmCodingModels;
      };
    };
  };

  sops.secrets."containers/litellm/master_key" = {};
  sops.templates."paseo-maki.env".content = ''
    ELENA_API_KEY=${config.sops.placeholder."containers/litellm/master_key"}
  '';
  systemd.services.paseo.serviceConfig = {
    EnvironmentFile = [config.sops.templates."paseo-maki.env".path];
    # When the host's MemoryMax on the container OOM-kills one agent, the
    # default (stop) would take every other agent down with it.
    OOMPolicy = "continue";
  };
}
