{
  lib,
  pkgs,
  config,
  secrets,
  ...
}:
with lib; let
  cfg = config.localModules.docker;
in {
  options.localModules.docker = {
    enable = mkEnableOption "docker";

    enableAutoPrune = mkOption {
      default = false;
      type = types.bool;
    };

    useLocalDns = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      enableNvidia = builtins.elem "nvidia" config.services.xserver.videoDrivers;
      liveRestore = false;
      autoPrune = mkIf cfg.enableAutoPrune {
        enable = true;
        flags = [
          "--all"
          "--filter \"until=168h\""
        ];
      };
      # Docker defaults to Google's DNS
      extraOptions = mkIf cfg.useLocalDns ''
        --dns ${secrets.network.home.nameserver} \
        --dns-search lan
      '';
    };
  };
}
