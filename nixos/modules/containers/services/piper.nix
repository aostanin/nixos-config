{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "piper";
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
      default = 10200;
    };

    voice = lib.mkOption {
      type = lib.types.str;
      default = "en-gb-southern_english_female-low";
    };
  };

  config = lib.mkIf (config.localModules.containers.enable && cfg.enable) {
    localModules.containers.services.${name} = {
      autoupdate = lib.mkDefault true;
    };

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "docker.io/rhasspy/wyoming-piper:latest";
        ports = ["${toString cfg.port}:10200"];
        volumes = ["${cfg.volumes.data.path}:/data"];
        cmd = ["--voice" cfg.voice];
      }
      mkContainerDefaultConfig
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.tmpfiles.rules = mkTmpfileVolumesConfig cfg.volumes;
  };
}
