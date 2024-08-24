{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "whisper";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    volumes = mkVolumesOption name {
      data = {};
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 10300;
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "tiny-int8";
    };

    language = lib.mkOption {
      type = lib.types.str;
      default = "en";
    };
  };

  config = lib.mkIf (config.localModules.containers.enable && cfg.enable) {
    localModules.containers.services.${name} = {
      autoupdate = lib.mkDefault true;
    };

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "docker.io/rhasspy/wyoming-whisper:latest";
        ports = ["${toString cfg.port}:10300"];
        volumes = ["${cfg.volumes.data.path}:/data"];
        cmd = ["--model" cfg.model "--language" cfg.language];
      }
      mkContainerDefaultConfig
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.tmpfiles.rules = mkTmpfileVolumesConfig cfg.volumes;
  };
}
