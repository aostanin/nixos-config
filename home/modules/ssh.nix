{
  pkgs,
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
          hostname = "roan";
          port = 2222;
          user = "git";
        };

        elena = {
          hostname = "roan";
          port = 2223;
        };

        pikvm.user = "root";
      };
    };

    # Avoid SSH persmission issues
    # ref: https://github.com/nix-community/home-manager/issues/322#issuecomment-1856128020
    home.file.".ssh/config" = {
      target = ".ssh/config_source";
      onChange = ''cat ~/.ssh/config_source > ~/.ssh/config && chmod 400 ~/.ssh/config'';
    };
  };
}
