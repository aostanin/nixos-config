{
  lib,
  pkgs,
  config,
  ...
}: let
  name = "litellm";
  cfg = config.localModules.containers.services.${name};

  # JSON is valid YAML, and rendering through a sops template keeps MCP
  # credentials out of the world-readable store path a `pkgs.formats` file
  # would land in. litellm resolves `os.environ/` for general_settings but not
  # for mcp_servers, so those tokens have to be in the file itself.
  configContent = builtins.toJSON ({
      model_list = cfg.models;
      general_settings.master_key = "os.environ/LITELLM_MASTER_KEY";
      litellm_settings = {
        drop_params = true;
        num_retries = 2;
      };
    }
    // lib.optionalAttrs (cfg.mcpServers != {}) {mcp_servers = cfg.mcpServers;});
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    models = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
      default = [];
      description = "litellm `model_list` entries (each `{ model_name; litellm_params; }`).";
    };

    mcpServers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
      default = {};
      description = ''
        litellm `mcp_servers`, keyed by server name. Values may embed
        `config.sops.placeholder.<key>`; the config is rendered as a sops
        template, so tokens never reach the nix store.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."containers/${name}/master_key" = {};

    # The rendered path is stable, so a content-only change leaves the unit
    # identical and nothing would restart: the container would keep serving the
    # old file through a stale bind mount. sops-nix restarts it instead.
    sops.templates."${name}.env" = {
      content = ''
        LITELLM_MASTER_KEY=${config.sops.placeholder."containers/${name}/master_key"}
      '';
      restartUnits = ["podman-${name}.service"];
    };

    sops.templates."${name}-config.yaml" = {
      content = configContent;
      restartUnits = ["podman-${name}.service"];
    };

    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/berriai/litellm:main-stable";
      raw.cmd = ["--config" "/app/config.yaml" "--telemetry" "False"];
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      raw.volumes = ["${config.sops.templates."${name}-config.yaml".path}:/app/config.yaml:ro"];
      healthcheck = {
        cmd = "python3 -c \"import urllib.request; urllib.request.urlopen('http://localhost:4000/health/liveliness')\"";
        startPeriod = "30s";
      };
      proxy.enable = true;
    };
  };
}
