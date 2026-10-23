{
  pkgs,
  config,
  lib,
  localLib,
  secrets,
  ...
}: let
  cfg = config.localModules."ai";
  makiKeys = {
    elena = "containers/litellm/master_key";
    mac = "splash/api_key";
  };
in {
  options.localModules."ai" = {
    enable = lib.mkEnableOption "ai";
  };

  config = lib.mkIf cfg.enable {
    programs.mcp = {
      enable = true;
      servers = {
        nixos = {
          type = "stdio";
          command = lib.getExe pkgs.mcp-nixos;
        };
      };
    };

    programs.claude-code = {
      enable = true;
      package = pkgs.llm-agents.claude-code;
      mcpServers = config.programs.mcp.servers;
      rulesDir = ./rules;
      skills = ./skills;
      settings = {
        model = "claude-opus-5-5";
        effortLevel = "high";
        modelSettings.claude-opus-5-5.effortLevel = "high";
        tui = "fullscreen";
        permissions.defaultMode = "auto";
        skipAutoPermissionPrompt = true;
        agentPushNotifEnabled = true;
        includeCoAuthoredBy = false;
        attribution = {
          commit = "";
          pr = "";
          sessionUrl = false;
        };
        env = {
          ENABLE_CLAUDEAI_MCP_SERVERS = false;
          DO_NOT_TRACK = "0";
        };
      };
    };

    # Maki has no rules directory, only one global instruction file.
    xdg.configFile."maki/AGENTS.md".text =
      lib.concatMapStringsSep "\n" builtins.readFile (lib.filesystem.listFilesRecursive ./rules);

    xdg.configFile."maki/providers.toml".source = (pkgs.formats.toml {}).generate "maki-providers.toml" {
      elena = {
        display_name = "Custom (elena)";
        protocol = "openai";
        base_url = "https://litellm.${secrets.domain}/v1";
        discover_models = true;
      };
      # Over the tailnet so it also works offline on the Mac itself.
      mac = {
        display_name = "Custom (mac)";
        protocol = "openai";
        base_url = "http://${secrets.network.tailscale.hosts.andreis-macbook-pro.address}:8085/v1";
        discover_models = true;
      };
    };

    # Without a saved model maki falls back to anthropic/*, which has no key here,
    # so it opens the login picker instead of starting.
    xdg.configFile."maki/init.lua".text = ''
      maki.setup({
        provider = {
          default_model = "elena/ornith-1.5-35b-a3b",
          excluded_models = { "*/whisper*", "*/kokoro*" },
        },
        plugins = {
          -- Local servers slow down as parallel subagents share one GPU.
          task = { max_concurrent = 1 },
        },
      })
    '';

    # Keys go where `maki auth login` saves them, not into the environment.
    sops.secrets = lib.mapAttrs' (_: secret: lib.nameValuePair secret {}) makiKeys;
    sops.templates = lib.mapAttrs' (slug: secret:
      lib.nameValuePair "maki-auth-${slug}" {
        mode = "0400";
        content = builtins.toJSON {api_key = config.sops.placeholder.${secret};};
      })
    makiKeys;
    xdg.stateFile = lib.mapAttrs' (slug: _:
      lib.nameValuePair "maki/auth/${slug}.json" {
        source = config.lib.file.mkOutOfStoreSymlink config.sops.templates."maki-auth-${slug}".path;
      })
    makiKeys;

    home.packages = with pkgs.llm-agents;
      localLib.filterAvailable [
        # Agents
        opencode
        pi
        pkgs.maki

        # Tools
        agent-browser
        rtk
      ]
      ++ lib.optional config.localModules.desktop.enable pkgs.paseo-desktop;
  };
}
