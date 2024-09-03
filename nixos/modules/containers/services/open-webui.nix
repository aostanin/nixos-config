{
  lib,
  config,
  ...
}: let
  name = "open-webui";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.services = {
      ollama.enable = true;
      openedai-speech.enable = lib.mkDefault true;
    };

    sops.secrets = {
      "containers/${name}/webui_secret_key" = {};
    };

    sops.templates."${name}.env".content = ''
      WEBUI_SECRET_KEY=${config.sops.placeholder."containers/${name}/webui_secret_key"}
    '';

    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/open-webui/open-webui:cuda";
      networks = ["ollama"];
      raw.dependsOn = ["ollama"];
      raw.environment = {
        OLLAMA_BASE_URL = "http://ollama:11434";
        ENABLE_SIGNUP = "false";
      };
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      volumes.data.destination = "/app/backend/data";
      raw.extraOptions = ["--device=nvidia.com/gpu=all"];
      proxy = {
        enable = true;
        names = ["ai"];
      };
    };
  };
}
