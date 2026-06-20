{
  lib,
  config,
  ...
}: let
  name = "qbittorrent";
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

    enableVpn = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    enableQbitManage = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    volumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra volumes to bind to the container.";
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "lscr.io/linuxserver/qbittorrent:latest";
      raw.dependsOn = lib.optional cfg.enableVpn "vpn";
      raw.environment = {
        PUID = toString cfg.uid;
        PGID = toString cfg.gid;
        WEBUI_PORT = toString 8113;
        DOCKER_MODS = "linuxserver/mods:universal-package-install";
        INSTALL_PACKAGES = "python3";
      };
      volumes = {
        config = {
          destination = "/config";
          user = toString cfg.uid;
          group = toString cfg.gid;
        };
        watch = {
          destination = "/downloads/torrent/watch";
          user = toString cfg.uid;
          group = toString cfg.gid;
        };
      };
      raw.volumes = cfg.volumes;
      raw.extraOptions = lib.optional cfg.enableVpn "--network=container:vpn";
      stopTimeout = 60;
      healthcheck = {
        cmd = "curl -f http://127.0.0.1:8113/";
        startPeriod = "60s";
      };
      proxy = lib.mkIf (!cfg.enableVpn) {
        enable = true;
        port = 8113;
      };
    };

    localModules.containers.containers.qbit_manage = lib.mkIf cfg.enableQbitManage {
      raw.image = "ghcr.io/stuffanthings/qbit_manage:latest";
      raw.dependsOn = ["qbittorrent"];
      raw.environment = {
        QBT_SCHEDULE = "30";
      };
      volumes = {
        config = {
          name = "qbit_manage";
          parent = name;
          destination = "/config";
        };
      };
      raw.volumes = cfg.volumes;
      raw.extraOptions = ["--pull=newer"];
    };

    localModules.containers.services.vpn.enable = lib.mkIf cfg.enableVpn true;

    localModules.ingress.${name} = lib.mkIf cfg.enableVpn {
      backendUrl = "http://${config.localModules.containers.services.vpn.hostname}:8113";
    };
  };
}
