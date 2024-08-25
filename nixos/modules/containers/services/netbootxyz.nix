{
  lib,
  config,
  containerLib,
  ...
}:
with containerLib; let
  name = "netbootxyz";
  cfg = config.localModules.containers.services.${name};
  uid = toString config.localModules.containers.uid;
  gid = toString config.localModules.containers.gid;
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
    autoupdate = containerLib.mkAutoupdateOption name;
    proxy = mkProxyOption name {port = 3000;};
    volumes = mkVolumesOption name {
      config = {
        user = uid;
        group = gid;
      };
      assets = {
        user = uid;
        group = gid;
      };
    };
  };

  config = lib.mkIf (config.localModules.containers.enable && cfg.enable) {
    localModules.containers.services.${name} = {
      autoupdate = lib.mkDefault true;
      proxy = {
        enable = lib.mkDefault true;
        tailscale.enable = lib.mkDefault true;
      };
    };

    virtualisation.oci-containers.containers.${name} = lib.mkMerge [
      {
        image = "docker.io/linuxserver/netbootxyz:latest";
        environment = {
          PUID = uid;
          PGID = gid;
        };
        ports = ["69:69/udp"];
        volumes = [
          "${cfg.volumes.config.path}:/config"
          "${cfg.volumes.assets.path}:/assets"
        ];
      }
      mkContainerDefaultConfig
      (mkContainerProxyConfig name cfg.proxy)
      (mkContainerAutoupdateConfig name cfg.autoupdate)
    ];

    systemd.services."podman-${name}" = mkServiceProxyConfig name cfg.proxy;

    systemd.tmpfiles.rules = mkTmpfileVolumesConfig cfg.volumes;
  };
}
