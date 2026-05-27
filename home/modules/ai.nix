{
  pkgs,
  config,
  lib,
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
      mcpServers = config.programs.mcp;
      settings = {
        effortLevel = "xhigh";
        permissions.defaultMode = "auto";
        skipAutoPermissionPrompt = true;
        agentPushNotifEnabled = true;
        includeCoAuthoredBy = false;
        attribution = {
          commit = "";
          pr = "";
        };
        env = {
          ENABLE_CLAUDEAI_MCP_SERVERS = false;
        };
      };
    };

    home.packages = with pkgs.llm-agents; [
      # Agents
      inputs.maki.packages.${pkgs.stdenv.hostPlatform.system}.default
      opencode
      pi

      # Tools
      agent-browser
      hunk
      nono
      rtk
      tuicr
    ];
  };
}
