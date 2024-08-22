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

    usePodman = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };

    enableNvidia = lib.mkOption {
      default = builtins.elem "nvidia" config.services.xserver.videoDrivers;
      type = lib.types.bool;
    };

    enableAutoPrune = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };

    useLocalDns = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = lib.mkIf (!cfg.usePodman) {
      enable = true;
      enableNvidia = cfg.enableNvidia;
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

    virtualisation.podman = lib.mkIf cfg.usePodman {
      enable = true;
      enableNvidia = cfg.enableNvidia;
      dockerCompat = true;
      dockerSocket.enable = true;
      autoPrune = lib.mkIf cfg.enableAutoPrune {
        enable = true;
        flags = [
          "--all"
          "--filter \"until=168h\""
        ];
      };
    };

    virtualisation.oci-containers.backend =
      if cfg.usePodman
      then "podman"
      else "docker";

    environment.systemPackages = with pkgs;
      [
        dive
      ]
      ++ (
        if cfg.usePodman
        then [
          podman-compose
          podman-tui
        ]
        else [
          docker-compose
        ]
      );

    hardware.opengl = lib.mkIf cfg.enableNvidia {
      enable = true;
      driSupport32Bit = true;
    };
  };
}
