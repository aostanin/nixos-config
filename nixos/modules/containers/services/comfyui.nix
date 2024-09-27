{
  lib,
  config,
  secrets,
  ...
}: let
  name = "comfyui";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    enableNvidia = lib.mkOption {
      type = lib.types.bool;
      default = config.localModules.podman.enableNvidia;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."forgejo/registry_token" = {};

    localModules.containers.containers.${name} = {
      raw.image = "${secrets.forgejo.registry}/${secrets.forgejo.username}/stable-diffusion-webui-docker:comfy";
      raw.login = {
        inherit (secrets.forgejo) registry username;
        passwordFile = config.sops.secrets."forgejo/registry_token".path;
      };
      volumes = {
        data.destination = "/data";
        output.destination = "/output";
        models = {
          destination = "/data/models";
          storageType = "bulk";
        };
      };
      raw.extraOptions = lib.mkIf cfg.enableNvidia ["--device=nvidia.com/gpu=all"];
      proxy = {
        enable = true;
        port = 7860;
      };
    };
  };
}
