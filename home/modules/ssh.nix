{
  config,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules.ssh;
in {
  options.localModules.ssh = {
    enable = lib.mkEnableOption "ssh";
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*".extraOptions.StrictHostKeyChecking = "no";

        "git.${secrets.domain}" = {
          hostname = "roan.${secrets.terranix.tailscale.tailnetName}";
          port = 2222;
          user = "git";
        };
      };
    };
  };
}
