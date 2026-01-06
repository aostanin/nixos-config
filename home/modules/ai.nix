{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules."ai";
in {
  options.localModules."ai" = {
    enable = lib.mkEnableOption "ai";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      unstable.claude-code
      unstable.opencode
    ];
  };
}
