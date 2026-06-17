{
  lib,
  pkgs,
  config,
  ...
}: let
  name = "open-meteo";
  cfg = config.localModules.containers.services.${name};
  image = "ghcr.io/open-meteo/open-meteo:latest";
  dataDir = "${config.localModules.containers.storage.bulk}/${name}/data";
  variablesArg = lib.concatStringsSep "," cfg.variables;
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    models = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["jma_msm" "ecmwf_ifs025"];
      description = ''
        Weather model ids to download (open-meteo `sync`). With several synced,
        the API's default `best_match` picks the highest-resolution model per
        location (e.g. jma_msm over Japan, a global model elsewhere).
      '';
    };

    variables = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "temperature_2m"
        "relative_humidity_2m"
        "precipitation"
        "cloud_cover"
        "wind_speed_10m"
        "wind_direction_10m"
        "wind_gusts_10m"
        "shortwave_radiation"
      ];
      description = ''
        Raw model variables to download. open-meteo derives the rest at query
        time (apparent_temperature from temp/humidity/wind/radiation,
        weather_code from precipitation/cloud_cover). precipitation_probability
        is ensemble-only and stays null on deterministic models.
      '';
    };

    syncInterval = lib.mkOption {
      type = lib.types.str;
      default = "30min";
      description = "How often to re-run the data sync (systemd OnUnitActiveSec).";
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = image;
      volumes.data = {
        destination = "/app/data";
        storageType = "bulk";
        # The image runs as uid/gid 999 (openmeteo) and writes synced data here.
        user = "999";
        group = "999";
      };
      proxy = {
        enable = true;
        port = 8080;
      };
    };

    systemd.services."${name}-sync" = lib.mkIf (cfg.models != []) {
      description = "Sync open-meteo weather model data";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart =
          map (
            m: "${pkgs.podman}/bin/podman run --rm -v ${dataDir}:/app/data ${image} sync ${m} ${variablesArg}"
          )
          cfg.models;
      };
    };

    systemd.timers."${name}-sync" = lib.mkIf (cfg.models != []) {
      wantedBy = ["timers.target"];
      timerConfig = {
        # OnActiveSec (relative to timer start), not OnBootSec — so the first
        # sync fires a few minutes *after* a deploy, never during activation
        # (a sync failing mid-activation would otherwise roll back the deploy).
        OnActiveSec = "5min";
        OnUnitActiveSec = cfg.syncInterval;
      };
    };
  };
}
