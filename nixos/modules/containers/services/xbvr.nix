{
  lib,
  config,
  ...
}: let
  name = "xbvr";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    volumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra volumes to bind to the container.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "containers/${name}/ui_username" = {};
      "containers/${name}/ui_password" = {};
      "containers/${name}/deo_username" = {};
      "containers/${name}/deo_password" = {};
    };

    sops.templates."${name}.env".content = ''
      UI_USERNAME=${config.sops.placeholder."containers/${name}/ui_username"}
      UI_PASSWORD=${config.sops.placeholder."containers/${name}/ui_password"}
      DEO_USERNAME=${config.sops.placeholder."containers/${name}/deo_username"}
      DEO_PASSWORD=${config.sops.placeholder."containers/${name}/deo_password"}
    '';

    localModules.containers.containers.${name} = {
      raw.image = "ghcr.io/xbapps/xbvr:latest";
      raw.environmentFiles = [config.sops.templates."${name}.env".path];
      volumes.config.destination = "/root/.config";
      raw.volumes = cfg.volumes;
      proxy = {
        enable = true;
        port = 9999;
      };
    };
  };
}
