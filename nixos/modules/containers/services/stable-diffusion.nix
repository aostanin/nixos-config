{
  lib,
  config,
  secrets,
  ...
}: let
  name = "stable-diffusion";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."forgejo/registry_token" = {};

    localModules.containers.containers.${name} = {
      raw.image = "${secrets.forgejo.registry}/${secrets.forgejo.username}/stable-diffusion-webui-docker:auto";
      raw.login = {
        inherit (secrets.forgejo) registry username;
        passwordFile = config.sops.secrets."forgejo/registry_token".path;
      };
      raw.environment = {
        CLI_ARGS = "--allow-code --medvram --xformers --enable-insecure-extension-access --api";
      };
      volumes = {
        data.destination = "/data";
        output.destination = "/output";
        models = {
          destination = "/data/models";
          storageType = "bulk";
        };
      };
      raw.extraOptions = ["--device=nvidia.com/gpu=all"];
      proxy = {
        enable = true;
        port = 7860;
      };
    };
  };
}
