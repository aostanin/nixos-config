{
  lib,
  config,
  ...
}: let
  name = "karakeep";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    openai = {
      enable = lib.mkEnableOption "OpenAI-compatible AI tagging";

      textModel = lib.mkOption {
        type = lib.types.str;
        default = "gpt-4o-mini";
        description = "Model for text inference.";
      };

      imageModel = lib.mkOption {
        type = lib.types.str;
        default = "gpt-4o-mini";
        description = "Model for image inference.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets =
      {
        "containers/${name}/nextauth_secret" = {};
        "containers/${name}/meili_master_key" = {};
      }
      // lib.optionalAttrs cfg.openai.enable {
        "containers/${name}/openai_base_url" = {};
        "containers/${name}/openai_api_key" = {};
      };

    sops.templates."${name}.env".content =
      ''
        NEXTAUTH_SECRET=${config.sops.placeholder."containers/${name}/nextauth_secret"}
        MEILI_MASTER_KEY=${config.sops.placeholder."containers/${name}/meili_master_key"}
      ''
      + lib.optionalString cfg.openai.enable ''
        OPENAI_BASE_URL=${config.sops.placeholder."containers/${name}/openai_base_url"}
        OPENAI_API_KEY=${config.sops.placeholder."containers/${name}/openai_api_key"}
      '';

    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/karakeep-app/karakeep:release";
      networks = [name];
      raw.dependsOn = ["${name}-meilisearch" "${name}-chrome"];
      raw.environment =
        {
          NEXTAUTH_URL = "https://${name}.${config.localModules.containers.domain}";
          MEILI_ADDR = "http://${name}-meilisearch:7700";
          BROWSER_WEB_URL = "http://${name}-chrome:9222";
          DATA_DIR = "/data";
        }
        // lib.optionalAttrs cfg.openai.enable {
          INFERENCE_TEXT_MODEL = cfg.openai.textModel;
          INFERENCE_IMAGE_MODEL = cfg.openai.imageModel;
        };
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      volumes.data.destination = "/data";
      proxy.enable = true;
    };

    localModules.containers.containers."${name}-meilisearch" = {
      raw.image = "docker.io/getmeili/meilisearch:v1.13.3";
      networks = [name];
      raw.environment = {
        MEILI_NO_ANALYTICS = "true";
      };
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      volumes.data = {
        parent = name;
        destination = "/meili_data";
      };
    };

    localModules.containers.containers."${name}-chrome" = {
      raw.image = "gcr.io/zenika-hub/alpine-chrome:124";
      networks = [name];
      raw.cmd = [
        "--no-sandbox"
        "--disable-gpu"
        "--disable-dev-shm-usage"
        "--remote-debugging-address=0.0.0.0"
        "--remote-debugging-port=9222"
        "--hide-scrollbars"
      ];
    };
  };
}
