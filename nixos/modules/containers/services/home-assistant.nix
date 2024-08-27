{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "home-assistant";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption "home" {port = 8123;};
    volumes = mkVolumesOption name {
      config = {};
    };
  };

  config = lib.mkIf (config.localModules.containers.enable && cfg.enable) {
    localModules.containers.services.${name} = {
      autoupdate = lib.mkDefault true;
      proxy = {
        enable = lib.mkDefault true;
        net.enable = lib.mkDefault true;
      };
    };

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "ghcr.io/home-assistant/home-assistant:stable";
        volumes = [
          "${cfg.volumes.config.path}:/config"
          "/etc/localtime:/etc/localtime:ro"
          "/run/dbus:/run/dbus:ro"
        ];
        extraOptions = [
          "--privileged"
          "--network=host"
        ];
      }
      mkContainerDefaultConfig
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.tmpfiles.rules = mkTmpfileVolumesConfig cfg.volumes;
  };
}
