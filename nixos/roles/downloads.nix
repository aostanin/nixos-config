{
  config,
  lib,
  ...
}: let
  cfg = config.roles.downloads;
  qbittorrent = config.localModules.containers.services.qbittorrent;
  slice = "roles-downloads";

  usenet = "${cfg.downloadDir}/usenet:/downloads/usenet";
  torrentRo = "${cfg.downloadDir}/torrent:/downloads/torrent:ro";

  containers =
    ["nzbget" "qbittorrent" "sonarr" "radarr" "lidarr" "prowlarr" "bazarr" "jellyseerr"]
    ++ lib.optional qbittorrent.enableVpn "vpn"
    ++ lib.optional qbittorrent.enableQbitManage "qbit_manage";
in {
  options.roles.downloads = {
    enable = lib.mkEnableOption "Usenet and torrent downloads with the *arr stack";

    uid = lib.mkOption {
      type = lib.types.int;
      default = config.localModules.containers.uid;
    };

    gid = lib.mkOption {
      type = lib.types.int;
      default = config.localModules.containers.gid;
    };

    downloadDir = lib.mkOption {
      type = lib.types.str;
      example = "/srv/downloads";
      description = "Holds the `usenet` and `torrent` download directories.";
    };

    movieDir = lib.mkOption {
      type = lib.types.str;
      example = "/srv/media/movies";
    };

    tvDir = lib.mkOption {
      type = lib.types.str;
      example = "/srv/media/tv";
    };

    musicDir = lib.mkOption {
      type = lib.types.str;
      example = "/srv/media/music";
    };

    memoryMax = lib.mkOption {
      type = lib.types.str;
      default = "4G";
      description = "Memory limit for the whole role.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.localModules.containers.enable;
        message = "roles.downloads runs on localModules.containers";
      }
    ];

    localModules.containers.services = {
      nzbget = {
        enable = true;
        inherit (cfg) uid gid;
        volumes = [usenet];
      };
      qbittorrent = {
        enable = true;
        inherit (cfg) uid gid;
        volumes = ["${cfg.downloadDir}/torrent:/downloads/torrent"];
      };
      lidarr = {
        enable = true;
        inherit (cfg) uid gid;
        volumes = [torrentRo usenet "${cfg.musicDir}:/music"];
      };
      radarr = {
        enable = true;
        inherit (cfg) uid gid;
        volumes = [torrentRo usenet "${cfg.movieDir}:/movies"];
      };
      sonarr = {
        enable = true;
        inherit (cfg) uid gid;
        volumes = [torrentRo usenet "${cfg.tvDir}:/tv"];
      };
      prowlarr = {
        enable = true;
        inherit (cfg) uid gid;
      };
      bazarr = {
        enable = true;
        inherit (cfg) uid gid;
        volumes = ["${cfg.movieDir}:/movies" "${cfg.tvDir}:/tv"];
      };
      jellyseerr.enable = true;
    };

    localModules.containers.containers = lib.genAttrs containers (_: {slice = "${slice}.slice";});

    # No swap: a leak should hit the OOM killer instead of thrashing.
    systemd.slices.${slice}.sliceConfig = {
      MemoryMax = cfg.memoryMax;
      MemorySwapMax = "0";
    };
  };
}
