{
  lib,
  pkgs,
  config,
  ...
}: let
  name = "litellm";
  cfg = config.localModules.containers.services.${name};

  configFile =
    (pkgs.formats.yaml {}).generate "litellm-config.yaml"
    {
      model_list = cfg.models;
      general_settings.master_key = "os.environ/LITELLM_MASTER_KEY";
      litellm_settings = {
        drop_params = true;
        num_retries = 2;
      };
    };
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    models = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
      default = [];
      description = "litellm `model_list` entries (each `{ model_name; litellm_params; }`).";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."containers/${name}/master_key" = {};

    sops.templates."${name}.env".content = ''
      LITELLM_MASTER_KEY=${config.sops.placeholder."containers/${name}/master_key"}
    '';

    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/berriai/litellm:main-stable";
      raw.cmd = ["--config" "/app/config.yaml" "--telemetry" "False"];
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      raw.volumes = ["${configFile}:/app/config.yaml:ro"];
      healthcheck = {
        cmd = "python3 -c \"import urllib.request; urllib.request.urlopen('http://localhost:4000/health/liveliness')\"";
        startPeriod = "30s";
      };
      proxy.enable = true;
    };
  };
}
