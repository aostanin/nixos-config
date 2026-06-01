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
      settings = {
        "*".StrictHostKeyChecking = "no";

        "git.${secrets.domain}" = {
          HostName = "roan.${secrets.terranix.tailscale.tailnetName}";
          Port = 2222;
          User = "git";
        };
      };
    };
  };
}
