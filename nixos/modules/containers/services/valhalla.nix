{
  lib,
  config,
  ...
}: let
  name = "valhalla";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    pbfs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = ''
        Host paths to the .osm.pbf extracts to build routing tiles from. Multiple
        regional extracts can be combined into one graph (configure_valhalla globs
        all *.pbf in /custom_files). NOTE: a full planet build with elevation
        crashes this image's elevationbuilder (corrupts EdgeInfo offsets) — use
        regional extracts when buildElevation is enabled.
      '';
    };

    buildElevation = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Download elevation tiles covering the routing graph (~500G for planet)
        and enhance the graph with grade, enabling hill-aware bicycle/pedestrian
        costing and elevation profiles in responses. Needs forceRebuild = true
        for one deploy if the graph was already built without it.
      '';
    };

    forceRebuild = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Rebuild the routing graph even if tiles already exist. Flip on for one
        deploy after refreshing the .osm.pbf or enabling elevation, then off.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/nilsnolde/docker-valhalla/valhalla:latest";
      # planet extract (~179k tiles) loaded across server threads blows past the
      # default nofile limit -> "Too many open files" crash on startup. Raise it,
      # AND run as root so run.sh execs valhalla_service directly instead of via
      # sudo (sudo/pam would reset nofile back to a low default).
      raw.user = "0:0";
      raw.extraOptions = ["--ulimit" "nofile=1048576:1048576"];
      raw.environment = {
        use_tiles_ignore_pbf = "True";
        build_admins = "True";
        build_time_zones = "True";
        build_elevation =
          if cfg.buildElevation
          then "True"
          else "False";
        force_rebuild =
          if cfg.forceRebuild
          then "True"
          else "False";
      };
      volumes.data = {
        destination = "/custom_files";
        storageType = "bulk";
        user = "59999";
        group = "59999";
      };
      raw.volumes = map (p: "${p}:/custom_files/${baseNameOf p}:ro") cfg.pbfs;
      proxy = {
        enable = true;
        port = 8002;
      };
    };
  };
}
