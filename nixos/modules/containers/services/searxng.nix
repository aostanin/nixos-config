{
  lib,
  config,
  ...
}: let
  name = "searxng";
  cfg = config.localModules.containers.services.${name};
  settings = {
    use_default_settings = true;
    general.instance_name = "searxng";
    search = {
      autocomplete = "google";
      formats = ["html" "json"];
    };
    server = {
      port = 8080;
      bind_address = "0.0.0.0";
      base_url = "https://${lib.head (config.lib.containers.mkHosts "searx")}/";
      secret_key = config.sops.placeholder."containers/${name}/secret_key";
      method = "GET";
    };
    ui = {
      query_in_title = true;
      hotkeys = "vim";
    };
  };
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."containers/${name}/secret_key" = {};

    sops.templates."${name}-settings.yml" = {
      content = lib.generators.toYAML {} settings;
      uid = 977;
    };

    localModules.containers.containers.${name} = {
      raw.image = "docker.io/searxng/searxng:latest";
      raw.volumes = [
        "${config.sops.templates."${name}-settings.yml".path}:/etc/searxng/settings.yml:ro"
      ];
      healthcheck = {
        cmd = "wget -q --spider http://localhost:8080/healthz";
        startPeriod = "30s";
      };
      proxy = {
        enable = true;
        names = ["searx"];
        default.enable = true;
        default.auth = "authelia";
      };
    };
  };
}
