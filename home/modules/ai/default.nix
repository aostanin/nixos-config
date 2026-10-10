{
  pkgs,
  config,
  lib,
  localLib,
  inputs,
  ...
}: let
  cfg = config.localModules."ai";
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

    home.packages = with pkgs.llm-agents;
      localLib.filterAvailable [
        # Agents
        opencode
        pi
        pkgs.maki

        # Tools
        (localLib.brokenOnDarwin agent-browser)
        rtk
      ]
      ++ lib.optional config.localModules.desktop.enable
      inputs.paseo.packages.${pkgs.stdenv.hostPlatform.system}.desktop;
  };
}
