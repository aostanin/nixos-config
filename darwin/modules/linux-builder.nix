{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.localModules.linuxBuilder;
in {
  options.localModules.linuxBuilder = {
    enable = lib.mkEnableOption "linux-builder";
  };

  config = lib.mkIf cfg.enable {
    nix.linux-builder = {
      enable = true;
      ephemeral = true;
      config = {
        virtualisation = {
          darwin-builder.memorySize = 8 * 1024;
          cores = 4;
        };
      };
    };
  };
}
