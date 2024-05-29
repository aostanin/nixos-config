{
  lib,
  pkgs,
  config,
  secrets,
  ...
}: let
  cfg = config.localModules.docker;
in {
  options.localModules.docker = {
    enable = lib.mkEnableOption "docker";

    enableAutoPrune = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };

    useLocalDns = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable (let
    enableNvidia = builtins.elem "nvidia" config.services.xserver.videoDrivers;
  in {
    # TODO: Switch to podman
    virtualisation.docker = {
      enable = true;
      enableNvidia = enableNvidia;
      storageDriver = "overlay2";
      liveRestore = false;
      autoPrune = lib.mkIf cfg.enableAutoPrune {
        enable = true;
        flags = [
          "--all"
          "--filter \"until=168h\""
        ];
      };
      # Docker defaults to Google's DNS
      extraOptions = lib.mkIf cfg.useLocalDns ''
        --dns ${secrets.network.home.nameserver} \
        --dns-search lan
      '';
    };

    hardware.opengl = lib.mkIf enableNvidia {
      enable = true;
      driSupport32Bit = true;
    };
  });
}
