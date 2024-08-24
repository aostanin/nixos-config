{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "openwakeword";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    volumes = mkVolumesOption name {
      custom = {};
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 10400;
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "ok_nabu";
    };
  };

  config = lib.mkIf (config.localModules.containers.enable && cfg.enable) {
    localModules.containers.services.${name} = {
      autoupdate = lib.mkDefault true;
    };

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "docker.io/rhasspy/wyoming-openwakeword:latest";
        ports = ["${toString cfg.port}:10400"];
        volumes = ["${cfg.volumes.custom.path}:/custom"];
        cmd = ["--preload-model" cfg.model "--custom-model-dir" "/custom"];
      }
      mkContainerDefaultConfig
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.tmpfiles.rules = mkTmpfileVolumesConfig cfg.volumes;
  };
}
