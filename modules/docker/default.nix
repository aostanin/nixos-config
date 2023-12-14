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

  config = mkIf cfg.enable (let
    enableNvidia = builtins.elem "nvidia" config.services.xserver.videoDrivers;
  in {
    # TODO: Switch to podman
    virtualisation.docker = {
      enable = true;
      enableNvidia = enableNvidia;
      storageDriver = "overlay2";
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

    hardware.opengl = mkIf enableNvidia {
      enable = true;
      driSupport32Bit = true;
    };
  });
}
