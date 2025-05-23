{
  lib,
  pkgs,
  config,
  secrets,
  ...
}: let
  cfg = config.localModules.podman;
in {
  options.localModules.podman = {
    enable = lib.mkEnableOption "podman";

    enableNvidia = lib.mkOption {
      default = builtins.elem "nvidia" config.services.xserver.videoDrivers;
      type = lib.types.bool;
    };

    enableAutoPrune = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };

    enableAutoUpdate = lib.mkOption {
      default = true;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."podman/auth_file" = lib.mkIf cfg.enableAutoUpdate {};

    virtualisation.podman = {
      enable = true;
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

    virtualisation.oci-containers.backend = "podman";

    environment.systemPackages = with pkgs;
      [
        dive
        podman-compose
        podman-tui
      ]
      ++ lib.optional cfg.enableNvidia nvidia-container-toolkit;

    hardware = lib.mkIf cfg.enableNvidia {
      nvidia-container-toolkit.enable = true;

      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };

    systemd.timers.podman-auto-update = lib.mkIf cfg.enableAutoUpdate {
      enable = true;
      wantedBy = ["multi-user.target"];
      timerConfig.OnCalendar = "weekly";
    };

    systemd.services.podman-auto-update = lib.mkIf cfg.enableAutoUpdate {
      environment.REGISTRY_AUTH_FILE = config.sops.secrets."podman/auth_file".path;
    };

    # podman push is unstable with the default (6)
    virtualisation.containers.containersConf.settings.engine.image_parallel_copies = 1;
  };
}
