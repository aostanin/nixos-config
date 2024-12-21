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
      raw.image = "docker.io/linuxserver/qbittorrent:5.0.2";
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
    };

    localModules.containers.services.vpn.enable = lib.mkIf cfg.enableVpn true;

    services.traefik.dynamicConfigOptions = let
      hostRules =
        lib.concatStringsSep " || " (map (host: "Host(`${host}`)")
          (config.lib.containers.mkHosts name));
      trustedClientRules =
        lib.concatStringsSep " || " (map (host: "ClientIP(`${host}`)")
          config.lib.containers.trustedClientIps);
    in
      lib.mkIf cfg.enableVpn {
        http.routers.${name} = {
          rule = "(${trustedClientRules}) && (${hostRules})";
          entrypoints = "websecure";
          service = name;
        };
        http.services.${name}.loadbalancer.servers = [
          {url = "http://${config.localModules.containers.services.vpn.hostname}:8113";}
        ];
      };
  };
}
