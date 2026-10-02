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

  localModules = {
    common = {
      enable = true;
      minimal = true;
    };
    nix-ld.enable = true;
  };

  roles.dev = {
    enable = true;
    publicHostname = "paseo.${secrets.domain}";
    appsHostname = "paseoapps.${secrets.domain}";
    # Traefik on elena.
    trustedProxies = ["loopback" secrets.network.home.hosts.elena.address];
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
  systemd.services.paseo.serviceConfig.EnvironmentFile = [config.sops.templates."paseo-maki.env".path];
}
