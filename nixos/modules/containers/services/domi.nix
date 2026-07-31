{
  lib,
  pkgs,
  config,
  secrets,
  ...
}: let
  name = "domi";
  cfg = config.localModules.containers.services.${name};
  inherit (config.localModules.containers) domain;

  # A local archive is bind-mounted; an https:// upstream is read over the net.
  localPmtiles = lib.hasPrefix "/" cfg.upstreamPmtiles;

  configFile = (pkgs.formats.yaml {}).generate "${name}-config.yaml" {
    # The example config listens on loopback, which answers nothing from
    # outside the container. db.url and mcp.bearer_token come from the sops
    # env file, which overrides this file key-by-key.
    listen = "0.0.0.0:3000";
    object_store.path = "/var/lib/domi/objects";
    nats.url = "nats://${name}-nats:4222";
    overpass = {
      endpoint = cfg.overpassEndpoint;
      contact = cfg.contact;
    };
    poi.default_provider = "osm";
    routing = {
      default_router = "valhalla";
      default_elevation = "valhalla";
      valhalla.endpoint = cfg.valhallaEndpoint;
    };
    weather = {
      default_provider = "openmeteo";
      openmeteo = {
        endpoint = cfg.openMeteoEndpoint;
        contact = cfg.contact;
      };
    };
    web = {
      tile_url = cfg.tileUrl;
      attribution = ''<a href="https://github.com/protomaps/basemaps">Protomaps</a> © <a href="https://osm.org/copyright">OpenStreetMap</a>'';
    };
    tiles.upstream_pmtiles =
      if localPmtiles
      then "/srv/maps.pmtiles"
      else cfg.upstreamPmtiles;
  };
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    contact = lib.mkOption {
      type = lib.types.str;
      default = secrets.user.emailAddress;
      description = "Appended to the outbound User-Agent, per Overpass and Open-Meteo etiquette.";
    };

    overpassEndpoint = lib.mkOption {
      type = lib.types.str;
      default = "https://overpass.${domain}/api/interpreter";
      description = "Overpass API endpoint for the POI sweep.";
    };

    valhallaEndpoint = lib.mkOption {
      type = lib.types.str;
      default = "https://valhalla.${domain}";
      description = "valhalla_service endpoint for detour routing and Skadi elevation.";
    };

    openMeteoEndpoint = lib.mkOption {
      type = lib.types.str;
      default = "https://open-meteo.${domain}";
      description = "Open-Meteo endpoint for forecasts.";
    };

    tileUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://martin.${domain}/maps";
      description = ''
        Basemap vector tile source. Served to the browser via GET /config, so
        it must be reachable from the client and send CORS headers — not just
        reachable from the container.
      '';
    };

    upstreamPmtiles = lib.mkOption {
      type = lib.types.str;
      default = "/storage/appdata/openstreetmap/martin/tiles/maps.pmtiles";
      description = ''
        Source archive the per-event offline tile extract pulls from. An
        absolute path is bind-mounted read-only; an https:// URL is fetched.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "forgejo/registry_token" = {};
      "containers/${name}/postgres_password" = {};
      "containers/${name}/mcp_bearer_token" = {};
    };

    sops.templates."${name}.env".content = ''
      DOMI_SERVER__DB__URL=postgres://domi:${config.sops.placeholder."containers/${name}/postgres_password"}@${name}-db:5432/domi
      DOMI_SERVER__MCP__BEARER_TOKEN=${config.sops.placeholder."containers/${name}/mcp_bearer_token"}
    '';

    sops.templates."${name}-db.env".content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder."containers/${name}/postgres_password"}
    '';

    localModules.containers.containers.${name} = {
      raw.image = "${secrets.forgejo.registry}/${secrets.forgejo.username}/${name}:latest";
      raw.login = {
        inherit (secrets.forgejo) registry username;
        passwordFile = config.sops.secrets."forgejo/registry_token".path;
      };
      # :latest moves on every push to main; pull deliberately rather than have
      # a new build land mid-event.
      autoupdate = false;
      networks = [name];
      raw.dependsOn = ["${name}-db" "${name}-nats"];
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      raw.volumes =
        ["${configFile}:/etc/domi/config.yaml:ro"]
        ++ lib.optional localPmtiles "${cfg.upstreamPmtiles}:/srv/maps.pmtiles:ro";
      volumes = {
        # Raw GPX uploads and per-event PMTiles extracts.
        objects = {
          destination = "/var/lib/domi/objects";
          storageType = "bulk";
        };
        # The tiles export stages a whole extract here before copying it into
        # the object store, so it must not land on the writable layer.
        scratch = {
          destination = "/tmp";
          storageType = "temp";
        };
      };
      healthcheck = {
        cmd = "/bin/wget -q -O /dev/null http://127.0.0.1:3000/api/health";
        startPeriod = "30s";
      };
      # domi-server does not authenticate its REST surface at all; mcp.bearer_token
      # guards /mcp alone. Trusted networks only.
      proxy = {
        enable = true;
        port = 3000;
      };
    };

    localModules.containers.containers."${name}-db" = {
      raw.image = "docker.io/postgis/postgis:17-3.5-alpine";
      networks = [name];
      raw.environment = {
        POSTGRES_DB = "domi";
        POSTGRES_USER = "domi";
      };
      raw.environmentFiles = [config.sops.templates."${name}-db.env".path];
      # PostGIS parallel query allocates through /dev/shm, and the 64M default
      # is where "could not resize shared memory segment" comes from.
      raw.extraOptions = ["--shm-size=256m"];
      volumes.db = {
        parent = name;
        destination = "/var/lib/postgresql/data";
      };
      healthcheck = {
        # Over TCP, not the unix socket: the entrypoint runs a socket-only
        # server while it initialises the cluster, which a plain pg_isready
        # reports as healthy before the port anyone else uses is open.
        cmd = "pg_isready -U domi -d domi -h 127.0.0.1";
        interval = "10s";
        startPeriod = "30s";
      };
    };

    localModules.containers.containers."${name}-nats" = {
      raw.image = "docker.io/library/nats:2-alpine";
      networks = [name];
      # JetStream carries the job runner's work queue and is off by default;
      # http_port exists only for the health check.
      raw.cmd = ["--jetstream" "--store_dir" "/data" "--http_port" "8222"];
      volumes.data = {
        parent = name;
        destination = "/data";
      };
      healthcheck = {
        cmd = "wget -qO- http://127.0.0.1:8222/healthz";
        interval = "10s";
        startPeriod = "30s";
      };
    };
  };
}
