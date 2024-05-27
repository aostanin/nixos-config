{
  config,
  pkgs,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules.zerotier;
in {
  options.localModules.zerotier = {
    enable = lib.mkEnableOption "zerotier";
  };

  config = lib.mkIf cfg.enable {
    services.zerotierone = {
      enable = true;
      joinNetworks = [secrets.zerotier.network];
    };
  };
}
