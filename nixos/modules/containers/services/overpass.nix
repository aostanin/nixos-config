{
  lib,
  config,
  ...
}: let
  name = "overpass";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    pbf = lib.mkOption {
      type = lib.types.str;
      default = "/storage/appdata/openstreetmap/planet.osm.pbf";
      description = "Host path to the .osm.pbf to initialize the database from.";
    };

    meta = lib.mkOption {
      type = lib.types.enum ["no" "yes" "attic"];
      default = "no";
      description = ''
        OSM metadata to keep. `yes` adds timestamps/changeset/user info (larger,
        slower import); `attic` keeps full history (much larger).
      '';
    };

    diffUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "https://planet.openstreetmap.org/replication/day/";
      description = ''
        Replication directory to pull diffs from to keep the database current.
        When null (default) the database is a static snapshot of the imported
        pbf and no update daemon runs — refresh by re-importing a newer pbf.
      '';
    };

    updateSleep = lib.mkOption {
      type = lib.types.int;
      default = 86400;
      description = "Seconds between diff updates (only used when diffUrl is set).";
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/wiktorn/overpass-api:latest";
      raw.environment =
        {
          OVERPASS_MODE = "init";
          OVERPASS_META = cfg.meta;
          OVERPASS_PLANET_URL = "file:///osm/planet.osm.pbf";
          # The image fetches the URL to /db/planet.osm.bz2 then bzcat|imports,
          # i.e. it expects bzipped XML. Our source is PBF, so convert it in
          # place with osmium (ships in the image) before indexing. Per the
          # wiktorn README / issue #165.
          OVERPASS_PLANET_PREPROCESS = "mv /db/planet.osm.bz2 /db/planet.osm.pbf && osmium cat -o /db/planet.osm.bz2 /db/planet.osm.pbf && rm /db/planet.osm.pbf";
          OVERPASS_MAX_TIMEOUT = "1000";
        }
        // lib.optionalAttrs (cfg.diffUrl != null) {
          OVERPASS_DIFF_URL = cfg.diffUrl;
          OVERPASS_UPDATE_SLEEP = toString cfg.updateSleep;
        };
      volumes.db = {
        destination = "/db";
        storageType = "bulk";
      };
      raw.volumes = ["${cfg.pbf}:/osm/planet.osm.pbf:ro"];
      proxy = {
        enable = true;
        port = 80;
      };
    };
  };
}
