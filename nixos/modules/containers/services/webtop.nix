{
  lib,
  config,
  ...
}: let
  name = "webtop";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    uid = lib.mkOption {
      type = lib.types.int;
      default = config.localModules.containers.uid;
    };

    gid = lib.mkOption {
      type = lib.types.int;
      default = config.localModules.containers.gid;
    };

    additionalPackages = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      description = "Extra packages to install.";
    };

    devices = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      description = "Extra devices to bind to the container.";
    };

    volumes = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      description = "Extra volumes to bind to the container.";
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/linuxserver/webtop:latest";
      raw.environment = {
        PUID = toString cfg.uid;
        PGID = toString cfg.gid;
        DOCKER_MODS = "linuxserver/mods:universal-package-install";
        INSTALL_PACKAGES = lib.concatStringsSep " " cfg.additionalPackages;
      };
      volumes.config = {
        destination = "/config";
        user = toString cfg.uid;
        group = toString cfg.gid;
      };
      raw.volumes = cfg.volumes;
      raw.extraOptions =
        ["--privileged" "--shm-size=1gb" "--security-opt" "seccomp=unconfined"]
        ++ lib.map (d: "--device=${d}") cfg.devices;
      proxy = {
        enable = true;
        port = 3000;
      };
    };
  };
}
